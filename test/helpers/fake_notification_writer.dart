import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:salala/services/reminder_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

/// One alarm the app asked the phone to hold.
class WrittenAlarm {
  const WrittenAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.mode,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime at;
  final AndroidScheduleMode mode;
}

/// The app's own notification seam, with the platform channel removed.
///
/// `flutter test` has no notification channel to talk to, so the real plugin
/// would throw inside the call under test. Everything above it — which ids get
/// written, how many, in what order, at what hour, in which wording — is the
/// app's code, and a test using this still runs it for real.
class FakeNotificationWriter implements NotificationWriter {
  final List<WrittenAlarm> written = <WrittenAlarm>[];
  final List<int> cleared = <int>[];

  /// Every call in the order it was made, which is the only way to show stale
  /// alarms are cleared before new ones are written.
  final List<String> log = <String>[];

  /// Set to make [write] or [clear] throw, standing in for the phone refusing the
  /// alarm itself. The row it belongs to is already written by then, and nothing
  /// else in the test can say whether the screen knows the difference — which is
  /// exactly the difference D33 and D34 are made of.
  Object? writeFailure;
  Object? clearFailure;

  @override
  Future<void> initialise() async {}

  @override
  Future<void> write({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required AndroidScheduleMode mode,
  }) async {
    log.add('write');
    final failure = writeFailure;
    if (failure != null) throw failure;
    written.add(
      WrittenAlarm(id: id, title: title, body: body, at: at, mode: mode),
    );
  }

  @override
  Future<void> clear(int id) async {
    log.add('clear');
    final failure = clearFailure;
    if (failure != null) throw failure;
    cleared.add(id);
  }

  @override
  Future<void> clearAll() async {
    log.add('clearAll');
    // `cleared` stays untouched on purpose: it records ids the app named, and a
    // clear-all is the path where the app has no rows left to name.
    written.clear();
  }
}
