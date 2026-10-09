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

/// The record ids [bookingsFor] would have booked if their animals were at home,
/// but will not because they are not — the other half of the same walk, and the
/// half the phone is left holding an alarm for.
///
/// The reason it exists is measured on the device rather than inferred: an
/// animal edited to *Placed* went on waking its old breeder at 09:00 for a dose
/// she no longer owns. The filter added in Stage 3q was right — it refused to
/// re-book that dose — but refusing to re-book is not cancelling.
/// `flutter_local_notifications` persists what it was handed and re-arms it at
/// the next `initialize`, so a booking outlives both the filter and the app
/// process until something names its id and clears it.
///
/// A record whose two mornings have both passed is absent for the same reason it
/// is absent from [bookingsFor]: those alarms are behind the phone already, and
/// two platform calls for an alarm that cannot fire buys nothing.
List<String> staleRecordIds({
  required List<Vaccination> doses,
  required List<HealthTest> screenings,
  required Map<String, String> herd,
  DateTime? now,
}) {
  final from = now ?? DateTime.now();
  final stale = <String>[];

  void add(String recordId, String animalId, int? dueMs) {
    if (dueMs == null) return;
    if (herd.containsKey(animalId)) return;
    if (remindersFor(recordId: recordId, dueMs: dueMs, now: from).isEmpty) {
      return;
    }
    stale.add(recordId);
  }

  for (final dose in doses) {
    add(dose.id, dose.animalId, dose.nextDueDate);
  }
  for (final test in screenings) {
    add(test.id, test.animalId, test.validUntil);
  }
  return stale;
}

/// Reconciles one animal's alarms with the status that animal now has.
///
/// [resyncReminders] runs at launch and reads the herd through the horizon
/// query, so an edit that sends a dog away leaves her booked dose alone until
/// something cancels it. This is that something, and it is called from the
/// animal form right after the row is written: every dose and screening of
/// *this* animal is looked at, in or out of the horizon — the save path books
/// past the horizon, so the horizon query is not the whole record set.
Future<int> resyncAnimalReminders(
  ReminderScheduler scheduler, {
  required Daos daos,
  required String animalId,
  required AppLocalizations l10n,
  required String Function(int? ms) dueDayText,
  DateTime? now,
}) async {
  final animal = await daos.animals.findById(animalId);
  if (animal == null) return 0;
  return reconcile(
    scheduler,
    doses: await daos.vaccinations.forAnimal(animalId),
    screenings: await daos.healthTests.forAnimal(animalId),
    herd: <String, String>{if (animal.status.isAtHome) animal.id: animal.name},
    l10n: l10n,
    dueDayText: dueDayText,
    now: now,
  );
}

/// Rebuilds the phone's alarms from the ledger. Returns the records re-booked.
///
/// Called once per launch, because Android forgets an app's pending alarms when
/// the app is force-stopped or cleared from recents and there is no way for the
/// app to be woken to notice. The ledger is the durable copy, so the launch
/// reads it back instead of trusting the alarm manager to have kept them.
///
/// Reading it back means both halves of the comparison: what the ledger wants
/// booked gets written, and what it no longer wants gets taken out. A launch that
/// only re-books leaves a sold dog's dose in the phone forever, because the
/// plugin re-arms its own persisted list whatever the herd map now says.
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

  return reconcile(
    scheduler,
    doses: doses,
    screenings: screenings,
    herd: herd,
    l10n: l10n,
    dueDayText: dueDayText,
    now: from,
  );
}

/// Writes what the herd map books and clears what it does not, for one set of
/// records. Returns the records re-booked.
///
/// Shared by the launch and by a single animal's edit so the two cannot drift
/// into giving the same question different answers — which is the failure mode
/// Stage 3q was written against. Cancelling first is what makes a re-book
/// idempotent; a record that is not booked any more is cleared rather than
/// quietly left.
Future<int> reconcile(
  ReminderScheduler scheduler, {
  required List<Vaccination> doses,
  required List<HealthTest> screenings,
  required Map<String, String> herd,
  required AppLocalizations l10n,
  required String Function(int? ms) dueDayText,
  DateTime? now,
}) async {
  final from = now ?? DateTime.now();
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
  for (final recordId in staleRecordIds(
    doses: doses,
    screenings: screenings,
    herd: herd,
    now: from,
  )) {
    await scheduler.cancel(recordId);
  }
  return rebooked;
}
