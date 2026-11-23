import '../data/db/settings_dao.dart';
import 'trial.dart';

/// What the store sells, and what each thing unlocks.
///
/// Two plans rather than one because a breeder with a single litter and a
/// breeder running two kennels are not the same buyer, and a single price either
/// overcharges the first or leaves the second's money on the table. Both unlock
/// the identical feature set: the difference is the number of kennels a breeder
/// is allowed to keep in one ledger, which is a limit enforced by the licence
/// text rather than by code. A plan that gated a *feature* the other plan had
/// would turn the upgrade screen into a comparison table nobody reads.
enum CompanionPlan { pro, studio }

/// How often a subscription is charged.
enum BillingPeriod { monthly, yearly }

/// One line item in the store.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.plan,
    required this.period,
  });

  /// The product id as typed into Play Console. Changing one here without
  /// creating it there is a purchase button that fails on every phone.
  final String id;
  final CompanionPlan plan;
  final BillingPeriod period;
}

/// The four products, in the order the upgrade screen lists them.
///
/// Yearly first: a breeder who reads the price of the monthly plan and stops has
/// been shown the more expensive way to buy the same thing, and the one honest
/// discount this app can offer is the two months a yearly plan does not charge.
const List<StoreProduct> kCompanionProducts = <StoreProduct>[
  StoreProduct(
    id: 'companion_pro_yearly',
    plan: CompanionPlan.pro,
    period: BillingPeriod.yearly,
  ),
  StoreProduct(
    id: 'companion_pro_monthly',
    plan: CompanionPlan.pro,
    period: BillingPeriod.monthly,
  ),
  StoreProduct(
    id: 'companion_studio_yearly',
    plan: CompanionPlan.studio,
    period: BillingPeriod.yearly,
  ),
  StoreProduct(
    id: 'companion_studio_monthly',
    plan: CompanionPlan.studio,
    period: BillingPeriod.monthly,
  ),
];

/// The free tier's allowances, in one place so a gate and the sentence that
/// explains it cannot drift apart.
class FreeAllowance {
  FreeAllowance._();

  /// Photos per animal before Pro. Three is enough to identify a dog: a face, a
  /// side, and the paper that came with her.
  static const int photosPerAnimal = 3;
}

/// What this phone has bought.
class Entitlement {
  const Entitlement(this.plans);

  const Entitlement.none() : plans = const <CompanionPlan>{};

  final Set<CompanionPlan> plans;

  bool get isEmpty => plans.isEmpty;

  bool get hasPro => plans.contains(CompanionPlan.pro);

  bool get hasStudio => plans.contains(CompanionPlan.studio);

  /// Either plan unlocks every feature: the tiers differ in kennels, not in what
  /// the app does.
  bool get unlocksEverything => hasPro || hasStudio;

  /// A stable string for the settings row: a `Set` has no order, and two phones
  /// with the same purchase must not disagree about what to write down.
  String encode() {
    final names = plans.map((plan) => plan.name).toList()..sort();
    return names.join(',');
  }

  static Entitlement decode(String? raw) {
    if (raw == null || raw.isEmpty) return const Entitlement.none();
    final plans = <CompanionPlan>{};
    for (final name in raw.split(',')) {
      for (final plan in CompanionPlan.values) {
        if (plan.name == name) plans.add(plan);
      }
    }
    return Entitlement(plans);
  }

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.plans.length == plans.length &&
      other.plans.containsAll(plans);

  @override
  int get hashCode => Object.hashAllUnordered(plans);
}

/// The seam between the app and Play Billing.
///
/// An interface rather than a direct plugin call because a widget test has no
/// store, and a purchase flow that can only be exercised on a phone with a test
/// card is a purchase flow nobody tests. The real implementation is the only
/// thing that imports `in_app_purchase`.
abstract class PurchaseGateway {
  /// Loads the four products with their localised prices. Empty when the store
  /// is unreachable, which the screen shows as a price it has not got yet rather
  /// than as a price of zero.
  Future<List<StoreOffer>> loadOffers();

  /// Starts a purchase. The answer is the entitlement the store confirmed, or
  /// null when the breeder backed out or the store failed.
  Future<Entitlement?> buy(String productId);

  /// Asks the store what this account already owns.
  Future<Entitlement> restore();
}

/// A product the store actually answered for: the id, plus the price string the
/// store wants printed.
class StoreOffer {
  const StoreOffer({
    required this.product,
    required this.price,
    required this.title,
  });

  final StoreProduct product;
  final String price;
  final String title;
}

/// Reads and writes the entitlement row, and answers the one question every gate
/// asks.
///
/// The row is a setting rather than a keystore entry for the same reason the
/// trial is: a pack restored onto a new phone carries what was bought, and Play
/// re-confirms it on the first launch anyway.
class BillingService {
  BillingService({required this.settings, this.gateway});

  final SettingsDao settings;
  final PurchaseGateway? gateway;

  Future<Entitlement> read() async =>
      Entitlement.decode(await settings.read(SettingKeys.ownedPlans));

  Future<void> write(Entitlement entitlement) =>
      settings.write(SettingKeys.ownedPlans, entitlement.encode());

  /// The launch-time check. Play is the source of truth: a subscription that
  /// lapsed must stop unlocking, and a purchase made on another phone must
  /// start. A failure leaves the stored row alone rather than locking a breeder
  /// out of what she paid for because the phone was in a shed.
  Future<Entitlement> refresh() async {
    final store = gateway;
    if (store == null) return read();
    try {
      final owned = await store.restore();
      await write(owned);
      return owned;
    } catch (_) {
      return read();
    }
  }

  Future<Entitlement?> buy(StoreProduct product) async {
    final store = gateway;
    if (store == null) return null;
    final owned = await store.buy(product.id);
    if (owned == null) return null;
    await write(owned);
    return owned;
  }
}

/// A store that sells nothing, used when billing is switched off and by tests.
///
/// Every answer is the honest one for a build that has not opened its till:
/// no products, no purchase, nothing owned.
class NoStoreGateway implements PurchaseGateway {
  const NoStoreGateway();

  @override
  Future<List<StoreOffer>> loadOffers() async => const <StoreOffer>[];

  @override
  Future<Entitlement?> buy(String productId) async => null;

  @override
  Future<Entitlement> restore() async => const Entitlement.none();
}

/// The one answer every call site asks for: may this feature be used today?
///
/// It exists so no screen has to know whether the question is about a trial, a
/// purchase or a build with billing switched off. The trial and the entitlement
/// are read together because they are two halves of one answer, and reading them
/// apart is how a screen ends up saying "expired" under a header that says
/// "Pro".
class ProAccess {
  const ProAccess({
    required this.billingEnabled,
    required this.owned,
    required this.trial,
  });

  final bool billingEnabled;
  final Entitlement owned;
  final TrialState trial;

  bool allows(ProFeature feature) => ProGate(
    billingEnabled: billingEnabled,
    proOwned: owned.unlocksEverything,
  ).allows(expired: trial.expired, feature: feature);

  /// True when the breeder has paid, whatever the trial says.
  bool get paid => owned.unlocksEverything;

  /// True while the free trial is running and nothing has been bought.
  bool get inTrial => !paid && !trial.expired;

  /// True when the gates are actually closed. A build with billing off is never
  /// "over".
  bool get expired => billingEnabled && !paid && trial.expired;
}
