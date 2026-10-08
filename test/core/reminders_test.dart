import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/reminders.dart';

/// A fixed noon: every case below is about which mornings are still ahead, and
/// a `DateTime.now()` in the fixture would make that depend on when CI ran.
final _now = DateTime(2026, 10, 5, 12);

int _day(int year, int month, int day) =>
    DateTime(year, month, day, 8).millisecondsSinceEpoch;

void main() {
  group('remindersFor', () {
    test(
      'a dose due in the far future gets both the month ahead and the day',
      () {
        final due = _day(2026, 12, 20);
        final reminders = remindersFor(recordId: 'abc', dueMs: due, now: _now);

        expect(reminders.map((r) => r.kind).toList(), [
          ReminderKind.headsUp,
          ReminderKind.dueToday,
        ]);
        expect(reminders[0].at, DateTime(2026, 11, 20, reminderHour));
        expect(reminders[1].at, DateTime(2026, 12, 20, reminderHour));
      },
    );

    test('no due date schedules nothing', () {
      expect(remindersFor(recordId: 'abc', dueMs: null, now: _now), isEmpty);
    });

    test('the month ahead counts days on a calendar, not hours on a clock', () {
      // Thirty days before 2 January is 3 December, whatever hour the row was
      // stored at and whatever the month's length: D31 makes a due date a date,
      // so the heads-up has to land on the date a breeder would count back to.
      // A subtraction of 720 hours instead drifts a day wherever the zone
      // shortens or lengthens a day — which Morocco does for Ramadan.
      final reminders = remindersFor(
        recordId: 'abc',
        dueMs: _day(2027, 1, 2),
        now: _now,
      );

      expect(reminders.first.at, DateTime(2026, 12, 3, reminderHour));
    });

    test('the month ahead is dropped once it has passed', () {
      final reminders = remindersFor(
        recordId: 'abc',
        dueMs: _day(2026, 10, 20),
        now: _now,
      );

      expect(reminders.map((r) => r.kind).toList(), [ReminderKind.dueToday]);
    });

    test('a due date that already lapsed schedules nothing', () {
      // The ledger row is badged overdue, which says the same thing louder than
      // an alarm would; a late notification is only noise.
      expect(
        remindersFor(recordId: 'abc', dueMs: _day(2026, 9, 1), now: _now),
        isEmpty,
      );
    });

    test('the same morning is still alarmed while it has not come', () {
      final reminders = remindersFor(
        recordId: 'abc',
        dueMs: _day(2026, 10, 5),
        now: DateTime(2026, 10, 5, 8),
      );

      expect(reminders.map((r) => r.kind).toList(), [ReminderKind.dueToday]);
    });

    test('a morning already gone is not reported late', () {
      final reminders = remindersFor(
        recordId: 'abc',
        dueMs: _day(2026, 10, 5),
        now: DateTime(2026, 10, 5, 23, 59),
      );

      expect(reminders, isEmpty);
    });

    test('the time of day the dose was due at is not used, only the day', () {
      final evening = DateTime(2026, 12, 20, 23).millisecondsSinceEpoch;
      final morning = DateTime(2026, 12, 20, 1).millisecondsSinceEpoch;
      final fromEvening = remindersFor(
        recordId: 'abc',
        dueMs: evening,
        now: _now,
      );
      final fromMorning = remindersFor(
        recordId: 'abc',
        dueMs: morning,
        now: _now,
      );

      expect(
        fromEvening.map((r) => r.at).toList(),
        fromMorning.map((r) => r.at).toList(),
      );
      expect(fromEvening.first.at.hour, reminderHour);
    });
  });

  group('notificationIdFor', () {
    test('the two kinds of one record never collide', () {
      expect(
        notificationIdFor('0f1e2d3c-4b5a-6789', ReminderKind.headsUp),
        isNot(notificationIdFor('0f1e2d3c-4b5a-6789', ReminderKind.dueToday)),
      );
    });

    test('the id is stable, so re-saving a dose replaces its own alarm', () {
      expect(
        notificationIdFor('0f1e2d3c-4b5a-6789', ReminderKind.headsUp),
        notificationIdFor('0f1e2d3c-4b5a-6789', ReminderKind.headsUp),
      );
    });

    test('a uuid is folded into a positive signed 32-bit int', () {
      final ids =
          <String>[
            '0f1e2d3c-4b5a-6789-abcd-ef0123456789',
            'ffffffff-4b5a-6789-abcd-ef0123456789',
            '8.5',
            'short',
          ].expand(
            (uuid) =>
                ReminderKind.values.map((k) => notificationIdFor(uuid, k)),
          );

      for (final id in ids) {
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('different records get different ids', () {
      expect(
        notificationIdFor('0f1e2d3c-4b5a', ReminderKind.headsUp),
        isNot(notificationIdFor('0f1e2d4c-4b5a', ReminderKind.headsUp)),
      );
    });

    test('a heads-up is the even id and the due day the odd one', () {
      expect(
        notificationIdFor('0f1e2d3c', ReminderKind.headsUp).isEven,
        isTrue,
      );
      expect(
        notificationIdFor('0f1e2d3c', ReminderKind.dueToday).isOdd,
        isTrue,
      );
    });
  });
}
