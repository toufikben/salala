import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'package:companion/data/db/settings_dao.dart';
import 'package:companion/services/billing.dart';
import 'package:companion/services/billing_play.dart';

import '../helpers/test_db.dart';

/// A stand-in for Play, one level below the plugin.
///
/// `PlayPurchaseGateway` used to have no test at all, and that is exactly where
/// a real defect lived: the fake used by `billing_test` throws when the store is
/// unreachable, so the test asserting "a store that cannot be reached does not
/// lock a paying breeder out" passed while the real gateway returned an empty
/// entitlement. The suite and the phone disagreed, and only the phone was right.
///
/// Swapping `InAppPurchasePlatform.instance` lets the real gateway be driven by
/// a store that is offline, silent, or answers with a purchase — the three
/// things that matter and none of which a fake at the `PurchaseGateway` seam can
/// reproduce.
class _FakePlay extends InAppPurchasePlatform {
  _FakePlay({this.available = true});

  final bool available;
  final StreamController<List<PurchaseDetails>> _events =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// Product ids the platform will deliver when a restore is asked for.
  List<String> restored = <String>[];

  int restoreCalls = 0;
  bool completed = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _events.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls++;
    // Play does not answer synchronously: the events arrive after the call
    // returns, which is what the gateway's three-second silence is for.
    scheduleMicrotask(() {
      for (final id in restored) {
        _events.add(<PurchaseDetails>[_purchase(id)]);
      }
    });
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed = true;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    return ProductDetailsResponse(
      productDetails: <ProductDetails>[
        for (final id in ids)
          ProductDetails(
            id: id,
            title: id,
            description: id,
            price: 'DZD 1.00',
            rawPrice: 1,
            currencyCode: 'DZD',
          ),
      ],
      notFoundIDs: <String>[],
    );
  }

  void deliver(String productId) =>
      _events.add(<PurchaseDetails>[_purchase(productId)]);

  PurchaseDetails _purchase(String id) {
    final purchase = PurchaseDetails(
      purchaseID: 'tx-$id',
      productID: id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: '{}',
        source: 'google_play',
      ),
      transactionDate: '0',
      status: PurchaseStatus.restored,
    );
    // Play delivers restored purchases as unacknowledged, and an unacknowledged
    // purchase is refunded after three days.
    purchase.pendingCompletePurchase = true;
    return purchase;
  }

  Future<void> close() => _events.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlay play;
  late PlayPurchaseGateway gateway;

  setUpAll(() {
    // `InAppPurchase.instance` registers the real Android platform the first
    // time it is touched, which would overwrite the fake below. On a desktop
    // target it registers nothing, so the instance exists and the platform
    // choice stays ours. This is a test-only override; the shipped build never
    // sets it.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  setUp(() {
    play = _FakePlay();
    InAppPurchasePlatform.instance = play;
    gateway = PlayPurchaseGateway();
  });

  tearDown(() async {
    gateway.dispose();
    await play.close();
  });

  group('a store that cannot answer', () {
    test('a restore on an unreachable store does not report owning nothing', () async {
      // The dangerous answer. `BillingService.refresh` writes whatever comes
      // back, so returning "nothing owned" here erases the receipt of a breeder
      // who paid, on launch, with no network — and she is locked out of what she
      // bought until the store comes back.
      InAppPurchasePlatform.instance = _FakePlay(available: false);
      final offline = PlayPurchaseGateway();
      addTearDown(offline.dispose);

      expect(offline.restore, throwsA(isA<StateError>()));
    });

    test(
      'a silent store does not erase the receipt it was asked about',
      () async {
        // The end of the chain, and the reason the throw matters: a phone that
        // paid and then launches with a store that says nothing must still be
        // holding Pro afterwards. This is the sequence that ran on the phone.
        final settings = SettingsDao(await openTestDatabase());
        await BillingService(settings: settings)
            .write(const Entitlement(<CompanionPlan>{CompanionPlan.pro}));

        play.restored = <String>[];
        final service = BillingService(settings: settings, gateway: gateway);

        expect(
          await service.refresh(),
          const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
        );
        expect(
          await service.read(),
          const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
        );
      },
    );
  });

  group('a store that answers', () {
    test('a restored subscription is reported as owned', () async {
      play.restored = <String>['companion_pro_yearly'];
      final owned = await gateway.restore();
      expect(owned.hasPro, isTrue);
    });

    test('a restored purchase is acknowledged so Play does not refund it', () async {
      // An unacknowledged purchase is refunded by Play after three days, so a
      // restore that does not complete the purchase silently un-sells the app.
      play.restored = <String>['companion_pro_monthly'];
      await gateway.restore();
      expect(play.completed, isTrue);
    });
  });
}
