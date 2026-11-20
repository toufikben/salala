import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../core/contact.dart';

/// The store's review card, behind a seam.
///
/// The real one is a Play Core dialog the app cannot draw, screenshot, or dismiss
/// on its own behalf, so nothing above this line can be tested against it. A
/// recorder in its place is what lets a widget test prove the row calls it — and,
/// more to the point, prove the row *says something* when the phone refuses.
///
/// The fallback is deliberate and not a failure path: a phone with no Play Store,
/// or one where the quota Android enforces has already been spent, answers "no
/// card" to a request that is otherwise fine. Opening the listing is the honest
/// second answer, because the breeder's intent was to rate the app and the store
/// page is where that happens.
abstract class ReviewService {
  const ReviewService();

  /// True if a card was shown; false if this phone cannot show one.
  Future<bool> request();
}

class StoreReviewService extends ReviewService {
  const StoreReviewService();

  @override
  Future<bool> request() async {
    final review = InAppReview.instance;
    try {
      // `isAvailable` and `requestReview` are two separate channel calls on
      // purpose: Android throws from the request itself on a device without
      // Play, and the check is the only way to reach the fallback instead of an
      // exception the tile would have to swallow.
      if (await review.isAvailable()) {
        await review.requestReview();
        return true;
      }
      await review.openStoreListing(
        // Empty on Android, which reads the package off the manifest instead;
        // Apple's platforms require it and iOS is deferred until then.
        appStoreId: AppContact.appStoreId.isEmpty
            ? null
            : AppContact.appStoreId,
      );
      return false;
    } catch (error) {
      // `openStoreListing` throws `UnsupportedError` on a desktop, and the review
      // card can throw on a phone whose Play Store is disabled. Neither is a
      // reason to leave an unhandled exception in a tap handler.
      debugPrint('Review request failed: $error');
      return false;
    }
  }
}
