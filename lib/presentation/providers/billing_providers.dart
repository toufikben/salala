import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/billing.dart';
import '../../services/billing_play.dart';
import '../../services/trial.dart';
import 'app_providers.dart';

/// The store, or nothing at all.
///
/// A build with `kBillingEnabled` false never constructs the Play adapter: the
/// plugin subscribes to a purchase stream in its constructor, and a widget test
/// has no platform channel to answer it. Keeping the fake here is what lets the
/// whole app — including the Settings row and every gate — be tested without a
/// store on the machine.
final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {
  if (!kBillingEnabled) return const NoStoreGateway();
  final gateway = PlayPurchaseGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// The store's answer about this phone. Overridden in tests by a fake gateway.
final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService(
    settings: ref.watch(settingsDaoProvider),
    gateway: ref.watch(purchaseGatewayProvider),
  );
});

/// What has been bought, as a value the UI can watch.
class EntitlementController extends AsyncNotifier<Entitlement> {
  @override
  Future<Entitlement> build() => ref.read(billingServiceProvider).read();

  /// Called once at launch: Play is the source of truth, and a subscription that
  /// lapsed has to stop unlocking without the breeder doing anything.
  Future<void> refreshFromStore() async {
    state = AsyncData(await ref.read(billingServiceProvider).refresh());
  }

  Future<bool> buy(StoreProduct product) async {
    final owned = await ref.read(billingServiceProvider).buy(product);
    if (owned == null) return false;
    state = AsyncData(owned);
    return true;
  }
}

final entitlementProvider =
    AsyncNotifierProvider<EntitlementController, Entitlement>(
      EntitlementController.new,
    );

/// The four products with the prices Play wants printed.
final storeOffersProvider = FutureProvider<List<StoreOffer>>((ref) {
  return ref.watch(purchaseGatewayProvider).loadOffers();
});

/// The trial, read once per screen that asks.
final trialProvider = FutureProvider<TrialState>((ref) {
  return TrialService(settings: ref.watch(settingsDaoProvider)).state();
});

/// Billing, ownership and the trial in one answer.
final proAccessProvider = FutureProvider<ProAccess>((ref) async {
  final owned = await ref.watch(entitlementProvider.future);
  final trial = await ref.watch(trialProvider.future);
  return ProAccess(
    billingEnabled: kBillingEnabled,
    owned: owned,
    trial: trial,
  );
});
