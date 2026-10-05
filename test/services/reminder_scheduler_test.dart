import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/core/utils/reminders.dart';
import 'package:salala/services/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/fake_notification_writer.dart';

/// The scheduling rules run for real, over a writer that records instead of
/// delivering. `bootstrap()` is the one part left out: it asks the phone which
/// timezone it is in, and there is no phone here.
void main() {
  late FakeNotificationWriter writer;
  late ReminderScheduler scheduler;
  late AppLocalizations l10n;

  setUp(() async {
    writer = FakeNotificationWriter();
    scheduler = ReminderScheduler(writer);
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// A due date far enough ahead that both reminders are still to come.
  int dueInSixtyDays() => DateTime.now()
      .add(const Duration(days: 60))
      .copyWith(hour: 15)
      .millisecondsSinceEpoch;

  Future<void> book({required String recordId, int? dueMs}) {
    return scheduler.replace(
      recordId: recordId,
      dueMs: dueMs ?? dueInSixtyDays(),
      l10n: l10n,
      title: 'Nala',
      what: 'Rabies',
      dueDay: '4 Dec 2026',
    );
  }

  group('replace', () {
    test('a booked dose writes the month ahead and the due morning', () async {
      await book(recordId: '0f1e2d3c-4b5a-6789-abcd-ef0123456789');

      expect(writer.written, hasLength(2));
      expect(writer.written.map((a) => a.id).toList(), <int>[
        notificationIdFor(
          '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
          ReminderKind.headsUp,
        ),
        notificationIdFor(
          '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
          ReminderKind.dueToday,
        ),
      ]);
      expect(writer.written.first.title, 'Nala');
      expect(
        writer.written.first.body,
        'Heads up: Rabies is due on 4 Dec 2026',
      );
      expect(writer.written.last.body, 'Rabies is due today');
    });

    test('both alarms are inexact on purpose', () async {
      await book(recordId: '0f1e2d3c-4b5a');

      // An exact alarm needs SCHEDULE_EXACT_ALARM, which Google Play audits, for
      // a message whose only deadline is "that morning".
      for (final alarm in writer.written) {
        expect(alarm.mode, AndroidScheduleMode.inexactAllowWhileIdle);
      }
    });

    test('they land at nine in the morning in the pinned zone', () async {
      final due = dueInSixtyDays();
      await book(recordId: '0f1e2d3c-4b5a', dueMs: due);

      final day = dayFromMs(due)!;
      expect(
        writer.written.last.at,
        tz.TZDateTime.from(
          DateTime(day.year, day.month, day.day, reminderHour),
          tz.local,
        ),
      );
      expect(writer.written.last.at.location, tz.local);
      for (final alarm in writer.written) {
        expect(alarm.at.hour, reminderHour);
        expect(alarm.at.minute, 0);
      }
    });

    test("the dose's own alarms are cleared before new ones are written", () async {
      await book(recordId: '0f1e2d3c-4b5a');

      // A dose moved two days on must not leave the old morning behind — and the
      // clearing has to come first, because writing first would cancel the new
      // alarm as easily as the stale one.
      expect(writer.log, <String>['clear', 'clear', 'write', 'write']);
    });

    test('a dose with no due date clears the alarms and writes none', () async {
      await book(recordId: '0f1e2d3c-4b5a', dueMs: null);

      expect(writer.written, isEmpty);
      expect(writer.cleared, hasLength(ReminderKind.values.length));
    });

    test('a certificate that already lapsed writes nothing new', () async {
      await book(
        recordId: '0f1e2d3c-4b5a',
        dueMs: DateTime.now()
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
      );

      expect(writer.written, isEmpty);
    });

    test('re-saving the same dose writes the same two ids again', () async {
      await book(recordId: '0f1e2d3c-4b5a');
      final firstPass = writer.written.map((a) => a.id).toList();
      writer.written.clear();

      await book(recordId: '0f1e2d3c-4b5a');

      // Stable ids are what let an edit replace its own alarm rather than pile a
      // second copy onto the phone.
      expect(writer.written.map((a) => a.id).toList(), firstPass);
    });

    test('the copy follows the language on screen', () async {
      final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        dueMs: dueInSixtyDays(),
        l10n: arabic,
        title: 'نالة',
        what: 'سعار',
        dueDay: '٤ ديسمبر ٢٠٢٦',
      );

      expect(writer.written.first.title, 'نالة');
      expect(writer.written.first.body, contains('سعار'));
      expect(writer.written.first.body, contains('٤ ديسمبر ٢٠٢٦'));
      expect(writer.written.last.body, contains('مستحق اليوم'));
    });
  });

  group('cancel', () {
    test("names both of the record's own ids and nobody else's", () async {
      await scheduler.cancel('0f1e2d3c-4b5a');

      expect(writer.cleared, <int>[
        notificationIdFor('0f1e2d3c-4b5a', ReminderKind.headsUp),
        notificationIdFor('0f1e2d3c-4b5a', ReminderKind.dueToday),
      ]);
    });
  });
}
