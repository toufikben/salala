import '../core/l10n/app_localizations.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/reminders.dart';
import '../data/db/daos.dart';
import '../data/models/health_test.dart';
import '../data/models/vaccination.dart';
import 'reminder_scheduler.dart';

/// One record handed back to the alarm manager, in the words its alarm needs.
///
/// The wording is decided here rather than inside [ReminderScheduler] because
/// the language on screen is only knowable from the widget tree, while which
/// records deserve an alarm is pure arithmetic worth testing on its own.
class ReminderBooking {
  const ReminderBooking({
    required this.recordId,
    required this.dueMs,
    required this.title,
    required this.what,
    required this.dueDay,
  });

  final String recordId;
  final int dueMs;
  final String title;
  final String what;
  final String dueDay;
}

/// Every record whose alarms are still ahead, for an animal still at home —
/// doses before screenings.
///
/// [herd] is the animal id → name map *of the animals the phone may wake for*:
/// built by [resyncReminders] off `AnimalStatus.isAtHome` (D40). A record whose
/// animal is not in it books nothing, for two different reasons that want the
/// same answer — the dog was sold or died, so the booking belongs to someone
/// else or to nobody; or the animal row is simply gone, so the alarm would name
/// nothing. This is the same rule the home agenda already applies to the same
/// rows, and the old code broke it: it kept both kinds of record and titled the
/// message with the app's name, which is a 09:00 notification about a dose
/// nobody can act on.
///
/// A record whose two mornings have both passed is skipped rather than passed to
/// [ReminderScheduler.replace]: cancelling an alarm that is not there costs two
/// calls to the platform for nothing, and an overdue dose is already shouting
/// about itself in the ledger.
List<ReminderBooking> bookingsFor({
  required List<Vaccination> doses,
  required List<HealthTest> screenings,
  required Map<String, String> herd,
  required String Function(int? ms) dueDayText,
  DateTime? now,
}) {
  final from = now ?? DateTime.now();
  final bookings = <ReminderBooking>[];

  void add(String recordId, String animalId, int? dueMs, String what) {
    if (dueMs == null) return;
    final name = herd[animalId];
    if (name == null) return;
    if (remindersFor(recordId: recordId, dueMs: dueMs, now: from).isEmpty) {
      return;
    }
    bookings.add(
      ReminderBooking(
        recordId: recordId,
        dueMs: dueMs,
        title: name,
        what: what,
        dueDay: dueDayText(dueMs),
      ),
    );
  }

  for (final dose in doses) {
    add(dose.id, dose.animalId, dose.nextDueDate, dose.vaccineName);
  }
  for (final test in screenings) {
    add(test.id, test.animalId, test.validUntil, test.testType);
  }
  return bookings;
}

/// Rebuilds the phone's alarms from the ledger. Returns the records re-booked.
///
/// Called once per launch, because Android forgets an app's pending alarms when
/// the app is force-stopped or cleared from recents and there is no way for the
/// app to be woken to notice. The ledger is the durable copy, so the launch
/// reads it back instead of trusting the alarm manager to have kept them.
Future<int> resyncReminders(
  ReminderScheduler scheduler, {
  required Daos daos,
  required AppLocalizations l10n,
  required String Function(int? ms) dueDayText,
  DateTime? now,
}) async {
  final from = now ?? DateTime.now();
  final cutoff = msFromDay(shiftDays(from, reminderHorizonDays));

  final doses = await daos.vaccinations.dueBefore(cutoff);
  final screenings = await daos.healthTests.expiringBy(cutoff);
  if (doses.isEmpty && screenings.isEmpty) return 0;

  final herd = <String, String>{
    for (final animal in await daos.animals.findAll())
      if (animal.status.isAtHome) animal.id: animal.name,
  };

  var rebooked = 0;
  for (final booking in bookingsFor(
    doses: doses,
    screenings: screenings,
    herd: herd,
    dueDayText: dueDayText,
    now: from,
  )) {
    await scheduler.replace(
      recordId: booking.recordId,
      dueMs: booking.dueMs,
      l10n: l10n,
      title: booking.title,
      what: booking.what,
      dueDay: booking.dueDay,
    );
    rebooked++;
  }
  return rebooked;
}
