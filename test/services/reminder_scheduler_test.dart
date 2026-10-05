import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/utils/reminders.dart';
import 'package:salala/services/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The plugin object with its platform channel removed.
///
/// `flutter test` has no notification channel to talk to, so the real
/// [FlutterLocalNotificationsPlugin] would throw inside the very call under
/// test. Everything above the channel — which ids are used, how many alarms are
/// written, that the old ones are cleared first, what the text says — is the
/// app's own code and is exercised for real here.
class RecordingPlugin extends FlutterLocalNotificationsPlugin {
  final List<_Written> written = <_Written>[];
  final List<int> cancelled = <int>[];

  /// Every call in the order the scheduler made them, which is the only way to
  /// assert that stale alarms are cleared before new ones are written.
  final List<String> log = <String>[];

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    log.add('write');
    written.add(
      _Written(
        id: id,
        at: scheduledDate,
        title: title ?? '',
        body: body ?? '',
        mode: androidScheduleMode,
      ),
    );
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    log.add('cancel');
    cancelled.add(id);
  }
}

class _Written {
  const _Written({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.mode,
  });

  final int id;
  final tz.TZDateTime at;
  final String title;
  final String body;
  final AndroidScheduleMode mode;
}

/// A due date far enough ahead that both reminders are still to come.
int _dueInSixtyDays() => DateTime.now()
    .add(const Duration(days: 60))
    .copyWith(hour: 15)
    .millisecondsSinceEpoch;

void main() {
  late RecordingPlugin plugin;
  late ReminderScheduler scheduler;
  late AppLocalizations l10n;

  setUp(() async {
    plugin = RecordingPlugin();
    scheduler = ReminderScheduler(plugin: plugin);
    // The scheduler hands wall-clock times to `timezone`, which refuses to
    // convert any of them until its tables are loaded and a zone is pinned —
    // exactly the two things `bootstrap()` does in the app.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('replace', () {
    test('a booked dose writes the month ahead and the due morning', () async {
      final due = _dueInSixtyDays();
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
        dueMs: due,
        l10n: l10n,
        title: 'Nala',
        what: 'Rabies',
        dueDay: '4 Dec 2026',
      );

      expect(plugin.written, hasLength(2));
      expect(plugin.written.map((w) => w.id).toList(), [
        notificationIdFor(
          '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
          ReminderKind.headsUp,
        ),
        notificationIdFor(
          '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
          ReminderKind.dueToday,
        ),
      ]);
      expect(plugin.written.first.title, 'Nala');
      expect(
        plugin.written.first.body,
        'Heads up: Rabies is due on 4 Dec 2026',
      );
      expect(plugin.written.last.body, 'Rabies is due today');
    });

    test('both alarms are inexact on purpose', () async {
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: _dueInSixtyDays(),
        l10n: l10n,
        title: 'Nala',
        what: 'Rabies',
        dueDay: '4 Dec 2026',
      );

      // An exact alarm needs SCHEDULE_EXACT_ALARM, which Google Play audits. The
      // reminder's only deadline is "that morning", so it never gets one.
      for (final written in plugin.written) {
        expect(written.mode, AndroidScheduleMode.inexactAllowWhileIdle);
      }
    });

    test('they land at nine in the morning in the pinned zone', () async {
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: _dueInSixtyDays(),
        l10n: l10n,
        title: 'Nala',
        what: 'Rabies',
        dueDay: '4 Dec 2026',
      );

      for (final written in plugin.written) {
        expect(written.at.hour, reminderHour);
        expect(written.at.minute, 0);
      }
    });

    test("re-saving clears the dose's own alarms first", () async {
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: _dueInSixtyDays(),
        l10n: l10n,
        title: 'Nala',
        what: 'Rabies',
        dueDay: '4 Dec 2026',
      );

      // Both kinds, and before anything is written: a dose moved two days on must
      // not leave the old morning behind, and writing first would cancel the new
      // alarm as easily as the stale one.
      expect(plugin.cancelled, hasLength(ReminderKind.values.length));
      expect(plugin.log, <String>['cancel', 'cancel', 'write', 'write']);
    });

    test('a dose with no due date clears the alarms and writes none', () async {
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: null,
        l10n: l10n,
        title: 'Nala',
        what: 'Rabies',
        dueDay: '',
      );

      expect(plugin.written, isEmpty);
      expect(plugin.cancelled, hasLength(ReminderKind.values.length));
    });

    test('a screening lapse date in the past writes nothing new', () async {
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: DateTime.now()
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
        l10n: l10n,
        title: 'Nala',
        what: 'OFA hips',
        dueDay: '30 Sep 2026',
      );

      expect(plugin.written, isEmpty);
    });

    test('the copy follows the language on screen', () async {
      final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: _dueInSixtyDays(),
        l10n: arabic,
        title: 'نالة',
        what: 'كلب مسعور',
        dueDay: '٤ ديسمبر ٢٠٢٦',
      );

      expect(plugin.written.first.body, contains('كلب مسعور'));
      expect(plugin.written.first.body, contains('٤ ديسمبر ٢٠٢٦'));
    });
  });

  group('cancel', () {
    test('names both of the record\'s own ids and nobody else\'s', () async {
      await scheduler.cancel('0f1e2d3c-4b5a');

      expect(plugin.cancelled, <int>[
        notificationIdFor('0f1e2d3c-4b5a', ReminderKind.headsUp),
        notificationIdFor('0f1e2d3c-4b5a', ReminderKind.dueToday),
      ]);
    });
  });
}
