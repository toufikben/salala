import 'date_utils.dart';

/// A dose or a screening certificate is only useful if someone is told before
/// it lapses. Two moments are worth interrupting a breeder for: a month ahead,
/// which is the window a clinic appointment actually needs, and the morning it
/// falls due.
const int reminderLeadDays = 30;

/// Reminders land at nine in the morning, local time: early enough to act on,
/// late enough that no phone goes off in a barn before sunrise.
const int reminderHour = 9;

enum ReminderKind { headsUp, dueToday }

/// One scheduled message for one record.
class Reminder {
  const Reminder({
    required this.recordId,
    required this.kind,
    required this.at,
  });

  final String recordId;
  final ReminderKind kind;

  /// Local wall-clock instant the notification should appear.
  final DateTime at;

  int get notificationId => notificationIdFor(recordId, kind);

  @override
  String toString() => 'Reminder($recordId, $kind, $at)';
}

/// Reminders still in the future for one due date, soonest first.
///
/// A moment that has already passed is dropped rather than delivered late: a
/// "booster due in 30 days" note arriving after the booster is noise, and the
/// ledger row already says the dose is overdue.
List<Reminder> remindersFor({
  required String recordId,
  required int? dueMs,
  DateTime? now,
}) {
  if (dueMs == null) return const <Reminder>[];
  final from = now ?? DateTime.now();
  final due = dayFromMs(dueMs)!;
  return <Reminder>[
        (
          kind: ReminderKind.headsUp,
          day: due.subtract(const Duration(days: reminderLeadDays)),
        ),
        (kind: ReminderKind.dueToday, day: due),
      ]
      .map(
        (candidate) => Reminder(
          recordId: recordId,
          kind: candidate.kind,
          at: DateTime(
            candidate.day.year,
            candidate.day.month,
            candidate.day.day,
            reminderHour,
          ),
        ),
      )
      .where((reminder) => reminder.at.isAfter(from))
      .toList();
}

/// Android identifies a notification by a 32-bit int, and re-saving a record
/// has to replace its own reminders rather than pile up a second copy.
///
/// The record id is a uuid, so its first seven hex digits are a stable 28-bit
/// space; doubling it leaves the low bit for the two kinds and stays inside a
/// signed int.
int notificationIdFor(String recordId, ReminderKind kind) {
  final head = recordId.length > 7 ? recordId.substring(0, 7) : recordId;
  final space =
      int.tryParse(head, radix: 16) ??
      head.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7FFFFFF);
  return space * 2 + (kind == ReminderKind.headsUp ? 0 : 1);
}
