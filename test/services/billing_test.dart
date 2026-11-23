import 'package:flutter_test/flutter_test.dart';
import 'package:companion/data/db/settings_dao.dart';
import 'package:companion/services/billing.dart';
import 'package:companion/services/trial.dart';

import '../helpers/test_db.dart';

/// A store that answers on command, so a purchase can be refused, delayed or
/// confirmed without a phone.
class _FakeStore implements PurchaseGateway {
  _FakeStore({this.owned = const Entitlement.none(), this.failRestore = false});

  Entitlement owned;
  bool failRestore;
  int restoreCalls = 0;
  final List<String> bought = <String>[];

  @override
  Future<List<StoreOffer>> loadOffers() async => kCompanionProducts
      .map(
        (product) =>
            StoreOffer(product: product, price: '£9.99', title: product.id),
      )
      .toList();

  @override
  Future<Entitlement?> buy(String productId) async {
    bought.add(productId);
    return owned.isEmpty ? null : owned;
  }

  @override
  Future<Entitlement> restore() async {
    restoreCalls++;
    if (failRestore) throw StateError('store unreachable');
    return owned;
  }
}

void main() {
  late SettingsDao settings;

  setUp(() async => settings = SettingsDao(await openTestDatabase()));

  group('what this phone owns', () {
    test('nothing is written until the store says so', () async {
      final billing = BillingService(settings: settings);
      expect(await billing.read(), const Entitlement.none());
    });

    test('a purchase survives a restart as the same plans', () async {
      final billing = BillingService(settings: settings);
      await billing.write(
        const Entitlement(<CompanionPlan>{CompanionPlan.studio}),
      );
      expect(
        await BillingService(settings: settings).read(),
        const Entitlement(<CompanionPlan>{CompanionPlan.studio}),
      );
    });

    test('a row nobody can read does not invent a plan', () async {
      await settings.write(SettingKeys.ownedPlans, 'studio,enterprise,pro');
      final owned = await BillingService(settings: settings).read();
      expect(owned.plans, <CompanionPlan>{
        CompanionPlan.pro,
        CompanionPlan.studio,
      });
    });

    test('two phones with the same purchase write the same row', () {
      const a = Entitlement(<CompanionPlan>{
        CompanionPlan.studio,
        CompanionPlan.pro,
      });
      const b = Entitlement(<CompanionPlan>{
        CompanionPlan.pro,
        CompanionPlan.studio,
      });
      expect(a.encode(), b.encode());
      expect(a, b);
    });
  });

  group('the store is the source of truth', () {
    test('a lapsed subscription stops unlocking on the next launch', () async {
      final store = _FakeStore(
        owned: const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
      );
      final billing = BillingService(settings: settings, gateway: store);
      await billing.write(
        const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
      );

      store.owned = const Entitlement.none();
      expect(await billing.refresh(), const Entitlement.none());
      expect(await billing.read(), const Entitlement.none());
    });

    test('a purchase made on another phone arrives here', () async {
      final store = _FakeStore(
        owned: const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
      );
      final billing = BillingService(settings: settings, gateway: store);
      expect(await billing.read(), const Entitlement.none());
      expect(await billing.refresh(), store.owned);
      expect(await billing.read(), store.owned);
    });

    test('a store that cannot be reached does not lock a paying breeder out', () async {
      final store = _FakeStore(
        owned: const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
        failRestore: true,
      );
      final billing = BillingService(settings: settings, gateway: store);
      await billing.write(
        const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
      );
      expect(
        await billing.refresh(),
        const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
      );
      expect(store.restoreCalls, 1);
    });

    test('a purchase the store refused writes nothing', () async {
      final store = _FakeStore();
      final billing = BillingService(settings: settings, gateway: store);
      final result = await billing.buy(kCompanionProducts.first);
      expect(result, isNull);
      expect(await billing.read(), const Entitlement.none());
      expect(store.bought, <String>[kCompanionProducts.first.id]);
    });
  });

  group('the gate', () {
    ProAccess access({
      required bool billingEnabled,
      required Entitlement owned,
      required bool expired,
    }) => ProAccess(
      billingEnabled: billingEnabled,
      owned: owned,
      trial: TrialState(daysLeft: expired ? 0 : 5, expired: expired),
    );

    test('a build that sells nothing locks nothing', () {
      final gate = access(
        billingEnabled: false,
        owned: const Entitlement.none(),
        expired: true,
      );
      for (final feature in ProFeature.values) {
        expect(gate.allows(feature), isTrue, reason: feature.name);
      }
      expect(gate.expired, isFalse);
    });

    test('inside the trial everything answers', () {
      final gate = access(
        billingEnabled: true,
        owned: const Entitlement.none(),
        expired: false,
      );
      for (final feature in ProFeature.values) {
        expect(gate.allows(feature), isTrue, reason: feature.name);
      }
      expect(gate.inTrial, isTrue);
    });

    test('either plan unlocks every feature, not only its own', () {
      for (final plan in CompanionPlan.values) {
        final gate = access(
          billingEnabled: true,
          owned: Entitlement(<CompanionPlan>{plan}),
          expired: true,
        );
        for (final feature in ProFeature.values) {
          expect(gate.allows(feature), isTrue, reason: '$plan / ${feature.name}');
        }
        expect(gate.paid, isTrue);
        expect(gate.inTrial, isFalse);
      }
    });

    test('after the trial the paid extras close and the ledger does not', () {
      final gate = access(
        billingEnabled: true,
        owned: const Entitlement.none(),
        expired: true,
      );
      for (final feature in ProFeature.values) {
        expect(gate.allows(feature), isFalse, reason: feature.name);
      }
      expect(gate.expired, isTrue);

      // The ledger itself is not a ProFeature: no animal, litter, dose or weight
      // can be taken away, because nothing here names one. Neither are the
      // backup or the pedigree: both are the breeder's own data, and the app
      // promises her records leave the phone whenever she says so.
      expect(ProFeature.values.length, 4);
    });
  });

  group('the free allowances', () {
    test('three pictures identify a dog and the fourth sells the plan', () {
      expect(FreeAllowance.photosPerAnimal, 3);
    });

    test('the backup and the pedigree are never gated', () {
      // "Your records are yours" is the app's promise: the only copy of a
      // ledger must leave the phone whenever the breeder says so, free. No
      // feature may name a backup or a pedigree.
      for (final feature in ProFeature.values) {
        expect(feature.name.contains('ackup'), isFalse, reason: feature.name);
        expect(feature.name.contains('edigree'), isFalse, reason: feature.name);
      }
    });
  });

  group('the products the store must hold', () {
    test('four ids, one per plan and period, and no duplicate', () {
      expect(kCompanionProducts.length, 4);
      expect(kCompanionProducts.map((p) => p.id).toSet().length, 4);
      final pairs = kCompanionProducts
          .map((p) => '${p.plan.name}/${p.period.name}')
          .toSet();
      expect(pairs.length, 4);
    });

    test('a build with billing off never reaches a store', () async {
      const store = NoStoreGateway();
      expect(await store.loadOffers(), isEmpty);
      expect(await store.buy('companion_pro_yearly'), isNull);
      expect(await store.restore(), const Entitlement.none());
    });
  });
}
