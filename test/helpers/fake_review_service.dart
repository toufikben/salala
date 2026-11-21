import 'dart:async';

import 'package:companion/services/review_service.dart';

/// The store's card, as a test runner sees it: it is never there.
///
/// [cards] is what the phone answers — true for a card shown, false for the store
/// page that the real service opens instead. [failure] makes the request throw,
/// which is the desktop `UnsupportedError` and the disabled-Play-Store case in one
/// shape, so the row's own catch is exercised rather than assumed.
///
/// [gate] keeps a request in flight until the test releases it. Without one the
/// fake answers inside a microtask, so a double tap's second tap lands after the
/// first has already finished — which is a test about nothing, because the state
/// the guard exists for never happens.
class FakeReviewService extends ReviewService {
  FakeReviewService({this.cards = true});

  bool cards;
  Object? failure;
  Completer<void>? gate;
  int requests = 0;

  @override
  Future<bool> request() async {
    requests++;
    final thrown = failure;
    if (thrown != null) throw thrown;
    final held = gate;
    if (held != null) await held.future;
    return cards;
  }
}
