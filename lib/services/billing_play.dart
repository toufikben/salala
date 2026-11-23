import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing.dart';

/// The only file that talks to Play Billing.
///
/// Kept apart from [BillingService] so every screen, gate and test works against
/// a plain interface: a phone with no store, no network and no test account can
/// still exercise the whole flow with a fake, and the day Play changes its API
/// the damage is one class rather than every call site.
class PlayPurchaseGateway implements PurchaseGateway {
  PlayPurchaseGateway({InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance {
    _subscription = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) => _failAll(),
    );
  }

  final InAppPurchase _iap;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  /// Product ids this account owns according to the store.
  final Set<String> _owned = <String>{};

  /// The purchase the UI is waiting on, if any.
  Completer<Entitlement?>? _pending;

  /// A restore in flight, collecting ids until the store goes quiet.
  Completer<Entitlement>? _restoring;

  /// Every product id we sell, for the ownership filter.
  static final Set<String> _ids = kCompanionProducts
      .map((product) => product.id)
      .toSet();

  @override
  Future<List<StoreOffer>> loadOffers() async {
    if (!await _iap.isAvailable()) return const <StoreOffer>[];

    final response = await _iap.queryProductDetails(_ids);
    final offers = <StoreOffer>[];
    for (final product in kCompanionProducts) {
      for (final details in response.productDetails) {
        if (details.id != product.id) continue;
        offers.add(
          StoreOffer(
            product: product,
            price: details.price,
            title: details.title,
          ),
        );
      }
    }
    // The store lists them in its own order, and the screen lists them in ours.
    offers.sort(
      (a, b) => kCompanionProducts
          .indexOf(a.product)
          .compareTo(kCompanionProducts.indexOf(b.product)),
    );
    return offers;
  }

  @override
  Future<Entitlement?> buy(String productId) async {
    if (!await _iap.isAvailable()) return null;

    final response = await _iap.queryProductDetails(<String>{productId});
    if (response.productDetails.isEmpty) return null;
    final details = response.productDetails.first;

    final completer = Completer<Entitlement?>();
    _pending = completer;

    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
    if (!started) {
      _pending = null;
      return null;
    }
    // A purchase that never reports back must not leave the button spinning: a
    // phone that lost the network mid-flow gets the "nothing was charged"
    // sentence after two minutes rather than a blocked screen forever.
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        _pending = null;
        return null;
      },
    );
  }

  @override
  Future<Entitlement> restore() async {
    if (!await _iap.isAvailable()) return Entitlement(_ownedNames());
    final completer = Completer<Entitlement>();
    _restoring = completer;

    await _iap.restorePurchases();

    // Play answers a restore as a burst of purchase events and says nothing when
    // the burst is over, so "finished" is a short silence. Three seconds is
    // longer than any burst observed and short enough that the Settings row does
    // not feel stuck.
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _restoring = null;
        return Entitlement(_ownedNames());
      },
    );
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_ids.contains(purchase.productID)) {
            _owned.add(purchase.productID);
          }
          // Unacknowledged purchases are refunded by Play after three days.
          if (purchase.pendingCompletePurchase) {
            unawaited(_iap.completePurchase(purchase));
          }
          _settle();
        case PurchaseStatus.error:
          _pending?.complete(null);
          _pending = null;
          _settle();
        case PurchaseStatus.canceled:
          _pending?.complete(null);
          _pending = null;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  void _settle() {
    final entitlement = Entitlement(_ownedNames());
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      _pending = null;
      pending.complete(entitlement);
    }
    final restoring = _restoring;
    if (restoring != null && !restoring.isCompleted) {
      _restoring = null;
      restoring.complete(entitlement);
    }
  }

  void _failAll() {
    _pending?.complete(null);
    _pending = null;
    final restoring = _restoring;
    if (restoring != null && !restoring.isCompleted) {
      _restoring = null;
      restoring.complete(Entitlement(_ownedNames()));
    }
  }

  /// Product ids back to plans. A product id in the list that is not one of ours
  /// is ignored rather than guessed at.
  Set<CompanionPlan> _ownedNames() {
    final plans = <CompanionPlan>{};
    for (final product in kCompanionProducts) {
      if (_owned.contains(product.id)) plans.add(product.plan);
    }
    return plans;
  }

  void dispose() {
    unawaited(_subscription.cancel());
  }
}
