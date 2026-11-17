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

  /// Books a dose the way a form does. [dueMs] is required and deliberately not
  /// defaulted: a `dueMs ?? farAhead()` here once turned the "no due date" case
  /// into a booked one without saying so, and the test that was supposed to
  /// catch that passed it instead.
  Future<void> book({required String recordId, required int? dueMs}) {
    return scheduler.replace(
      recordId: recordId,
      animalId: 'animal-nala',
      dueMs: dueMs,
      l10n: l10n,
      title: 'Nala',
      what: 'Rabies',
      dueDay: '4 Dec 2026',
    );
  }

  group('replace', () {
    test('a booked dose writes the month ahead and the due morning', () async {
      await book(
        recordId: '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
        dueMs: dueInSixtyDays(),
      );

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
      // The morning-of alarm says the task is small, because a breeder reading a
      // bare due date at six in the morning reads it as another thing she is
      // behind on.
      expect(
        writer.written.last.body,
        'Rabies is due today. Two minutes is enough',
      );
    });

    test('both alarms are inexact on purpose', () async {
      await book(recordId: '0f1e2d3c-4b5a', dueMs: dueInSixtyDays());

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
      // Built as a wall-clock time, not re-expressed from an instant.
      // `TZDateTime.from(DateTime(...), tz.local)` reads the runner's local
      // midnight-or-nine as an instant and shifts it into the pinned zone, which
      // is the very bug `_wallClock` exists to prevent: on a runner at +01 it
      // expected 08:00 for an alarm the phone should ring at 09:00. "Nine in the
      // morning" is a reading of the clock, so the expectation has to be built
      // the same way the scheduler builds it.
      expect(
        writer.written.last.at,
        tz.TZDateTime(tz.local, day.year, day.month, day.day, reminderHour),
      );
      expect(writer.written.last.at.location, tz.local);
      for (final alarm in writer.written) {
        expect(alarm.at.hour, reminderHour);
        expect(alarm.at.minute, 0);
      }
    });

    test("the dose's own alarms are cleared before new ones are written", () async {
      await book(recordId: '0f1e2d3c-4b5a', dueMs: dueInSixtyDays());

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
      final due = dueInSixtyDays();
      await book(recordId: '0f1e2d3c-4b5a', dueMs: due);
      final firstPass = writer.written.map((a) => a.id).toList();
      writer.written.clear();

      await book(recordId: '0f1e2d3c-4b5a', dueMs: due);

      // Stable ids are what let an edit replace its own alarm rather than pile a
      // second copy onto the phone.
      expect(writer.written.map((a) => a.id).toList(), firstPass);
    });

    test('the copy follows the language on screen', () async {
      final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
      await scheduler.replace(
        recordId: '0f1e2d3c-4b5a',
        animalId: 'animal-nala',
        dueMs: dueInSixtyDays(),
        l10n: arabic,
        title: 'نالة',
        what: 'سعار',
        dueDay: '٤ ديسمبر ٢٠٢٦',
      );

      expect(writer.written.first.title, 'نالة');
      expect(writer.written.first.body, contains('سعار'));
      expect(writer.written.first.body, contains('٤ ديسمبر ٢٠٢٦'));
      expect(writer.written.last.body, contains('موعدها اليوم'));
    });

    test('both mornings carry the animal the alarm is about', () async {
      await book(recordId: '0f1e2d3c-4b5a', dueMs: dueInSixtyDays());

      // The payload is the whole of the tap. A reminder says "Rabies is due" and
      // names the dog in its title; the breeder who taps it wants that dog, not
      // a herd to search through, so both mornings hand back her id.
      expect(writer.written.map((alarm) => alarm.payload).toList(), <String?>[
        'animal-nala',
        'animal-nala',
      ]);
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

    test('the wholesale clear empties the phone without naming a record', () async {
      await book(recordId: '0f1e2d3c-4b5a', dueMs: dueInSixtyDays());
      writer.log.clear();
      writer.cleared.clear();

      await scheduler.clearEverything();

      // One call, no ids: the paths that use it have no rows left to read an id
      // off, which is exactly why `cancel` could not do this job.
      expect(writer.log, <String>['clearAll']);
      expect(writer.cleared, isEmpty);
      expect(writer.written, isEmpty);
    });
  });
}
