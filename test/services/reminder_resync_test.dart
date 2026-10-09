import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/core/utils/reminders.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/services/reminder_resync.dart';
import 'package:salala/services/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/fake_notification_writer.dart';
import '../helpers/test_db.dart';

/// Which alarms a launch owes the phone, and what it says collecting them.
///
/// The clock is pinned rather than read off the machine: every rule here is
/// about which mornings are still ahead, so a test that asked the runner what
/// time it was could pass on one day and fail on the next.
void main() {
  // `main()` does this for the app, and `pumpSalala` does it for widget tests.
  // This file calls the real formatter, so it owes the same setup: without the
  // symbol tables a `DateFormat` throws on the first day it is asked to render.
  setUpAll(() => initializeDateFormatting());

  final noon = DateTime(2026, 10, 5, 12);
  final eight = DateTime(2026, 10, 5, 8);

  /// Local midnight, [days] from the pinned day — the shape a form stores.
  int dayAhead(int days) =>
      DateTime(2026, 10, 5).add(Duration(days: days)).millisecondsSinceEpoch;

  String dayText(int? ms) => formatDayFor('en', ms);

  /// Marks the day instead of formatting it, so an assertion says the booking
  /// carried the record's own due date without depending on a locale's pattern.
  String stampedDay(int? ms) => 'D$ms';

  Vaccination dose({
    String id = 'dose-1',
    String animalId = 'animal-1',
    String name = 'Rabies',
    required int? dueMs,
  }) => Vaccination(
    id: id,
    animalId: animalId,
    vaccineName: name,
    dateAdministered: dayAhead(-10),
    nextDueDate: dueMs,
    createdAt: 0,
    updatedAt: 0,
  );

  HealthTest screening({
    String id = 'test-1',
    String animalId = 'animal-1',
    String type = 'OFA hips',
    required int? untilMs,
  }) => HealthTest(
    id: id,
    animalId: animalId,
    testType: type,
    result: 'Good',
    testDate: dayAhead(-40),
    validUntil: untilMs,
    createdAt: 0,
    updatedAt: 0,
  );

  group('bookingsFor', () {
    test('a dose due tomorrow is re-booked under its animal', () {
      final bookings = bookingsFor(
        doses: <Vaccination>[dose(dueMs: dayAhead(1))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      expect(bookings, hasLength(1));
      final booking = bookings.single;
      expect(booking.recordId, 'dose-1');
      expect(booking.dueMs, dayAhead(1));
      expect(booking.title, 'Nala');
      expect(booking.what, 'Rabies');
      expect(booking.dueDay, stampedDay(dayAhead(1)));
    });

    test('one record is one booking however many alarms it carries', () {
      // Two months out is two alarms. The booking is still per record, because
      // `replace` clears the record's own ids before writing them again.
      final bookings = bookingsFor(
        doses: <Vaccination>[dose(dueMs: dayAhead(60))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      expect(bookings, hasLength(1));
    });

    test('a dose whose mornings have all passed is left alone', () {
      final bookings = bookingsFor(
        doses: <Vaccination>[dose(dueMs: dayAhead(-3))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      // Overdue is the ledger's own badge, not an alarm about nothing.
      expect(bookings, isEmpty);
    });

    test('a dose due this morning is booked only while it has not come', () {
      final stillToCome = bookingsFor(
        doses: <Vaccination>[dose(dueMs: dayAhead(0))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: eight,
      );
      final alreadyGone = bookingsFor(
        doses: <Vaccination>[dose(dueMs: dayAhead(0))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      expect(stillToCome, hasLength(1));
      expect(alreadyGone, isEmpty);
    });

    test(
      'a dose with no due date and a permanent certificate book nothing',
      () {
        final bookings = bookingsFor(
          doses: <Vaccination>[dose(dueMs: null)],
          screenings: <HealthTest>[screening(untilMs: null)],
          herd: const <String, String>{'animal-1': 'Nala'},
          dueDayText: stampedDay,
          now: noon,
        );

        expect(bookings, isEmpty);
      },
    );

    test('a screening is booked off its expiry and named by its type', () {
      final bookings = bookingsFor(
        doses: const <Vaccination>[],
        screenings: <HealthTest>[screening(untilMs: dayAhead(10))],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      expect(bookings, hasLength(1));
      expect(bookings.single.what, 'OFA hips');
      expect(bookings.single.dueMs, dayAhead(10));
    });

    test('a record outside the herd map books nothing', () {
      // D40. The map is the whole decision — sold, deceased and gone are the same
      // absence here, and `resyncReminders` is what turns status into absence.
      // The old behaviour was the opposite: keep the record and title the message
      // with the app's name, which the scheduler's own comment calls noise.
      final bookings = bookingsFor(
        doses: <Vaccination>[dose(animalId: 'gone', dueMs: dayAhead(1))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      expect(bookings, isEmpty);
    });

    test('a name in the herd map is enough to book, whatever the status was', () {
      // The pair of the test above: the record is not dropped for being about a
      // retired animal or a renamed one, only for its animal not being at home.
      // A booking that survived the filter must carry the animal's own name, not
      // a fallback nobody can act on.
      final bookings = bookingsFor(
        doses: <Vaccination>[dose(animalId: 'animal-1', dueMs: dayAhead(1))],
        screenings: const <HealthTest>[],
        herd: const <String, String>{'animal-1': 'Nala'},
        dueDayText: stampedDay,
        now: noon,
      );

      expect(bookings.single.title, 'Nala');
    });
  });

  group('resyncReminders', () {
    late Daos daos;
    late String animalId;
    late FakeNotificationWriter writer;
    late ReminderScheduler scheduler;
    late AppLocalizations l10n;

    setUp(() async {
      daos = Daos(await openTestDatabase());
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      writer = FakeNotificationWriter();
      scheduler = ReminderScheduler(writer);
      animalId = (await daos.animals.create(
        Animal(
          id: '',
          name: 'Nala',
          species: 'dog',
          sex: Sex.female,
          status: AnimalStatus.active,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 1,
      )).id;
    });

    Future<String> seedDose(int? dueMs) async {
      final created = await daos.vaccinations.create(
        Vaccination(
          id: '',
          animalId: animalId,
          vaccineName: 'Rabies',
          dateAdministered: dayAhead(-10),
          nextDueDate: dueMs,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 2,
      );
      return created.id;
    }

    Future<String> seedScreening(int? untilMs) async {
      final created = await daos.healthTests.create(
        HealthTest(
          id: '',
          animalId: animalId,
          testType: 'PENNFID',
          result: 'Clear',
          testDate: dayAhead(-5),
          validUntil: untilMs,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 3,
      );
      return created.id;
    }

    Future<String> seedAnimal(String name, AnimalStatus status) async {
      final created = await daos.animals.create(
        Animal(
          id: '',
          name: name,
          species: 'dog',
          sex: Sex.female,
          status: status,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 4,
      );
      return created.id;
    }

    Future<String> seedDoseFor(String id, int? dueMs) async {
      final created = await daos.vaccinations.create(
        Vaccination(
          id: '',
          animalId: id,
          vaccineName: 'Rabies',
          dateAdministered: dayAhead(-10),
          nextDueDate: dueMs,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 5,
      );
      return created.id;
    }

    Future<int> run() => resyncReminders(
      scheduler,
      daos: daos,
      l10n: l10n,
      dueDayText: dayText,
      now: noon,
    );

    test('an empty ledger re-books nothing', () async {
      expect(await run(), 0);
      expect(writer.written, isEmpty);
      expect(writer.log, isEmpty);
    });

    test(
      'a launch re-books a dose and a screening with every alarm still ahead',
      () async {
        final doseId = await seedDose(dayAhead(20));
        final testId = await seedScreening(dayAhead(40));

        expect(await run(), 2);

        // The dose is inside its own month ahead, so only its due morning is
        // left to come; the screening has both of its alarms still ahead.
        expect(writer.written, hasLength(3));
        expect(writer.written.map((a) => a.title).toSet(), <String>{'Nala'});
        expect(writer.written.map((a) => a.id).toSet(), <int>{
          notificationIdFor(doseId, ReminderKind.dueToday),
          notificationIdFor(testId, ReminderKind.headsUp),
          notificationIdFor(testId, ReminderKind.dueToday),
        });
        expect(
          writer.written.every((a) => a.at.hour == reminderHour),
          isTrue,
          reason: 'a launch must not wake a barn before sunrise',
        );
        expect(
          writer.written.map((a) => a.body).every((b) => !b.contains('{')),
          isTrue,
          reason: 'the placeholders are filled before the copy leaves the app',
        );
      },
    );

    test('a record beyond the horizon waits for a later launch', () async {
      await seedDose(dayAhead(reminderHorizonDays + 30));

      expect(await run(), 0);
      expect(writer.log, isEmpty);
    });

    test(
      'a second launch replaces its own alarms instead of piling up',
      () async {
        await seedDose(dayAhead(20));

        expect(await run(), 1);
        expect(await run(), 1);

        // Both ids are cleared before either is written again, so at no moment
        // does the phone hold two copies of the same reminder.
        expect(writer.log, <String>[
          'clear',
          'clear',
          'write',
          'clear',
          'clear',
          'write',
        ]);
        expect(writer.written.first.id, writer.written.last.id);
      },
    );

    test('an overdue dose is left out of the launch entirely', () async {
      await seedDose(dayAhead(-3));

      expect(await run(), 0);
      // No clears either: a launch with nothing to say stays silent instead of
      // walking the platform for a record the ledger already shows in red.
      expect(writer.log, isEmpty);
    });

    test('a launch books the animals at this address and no others', () async {
      // D40, end to end on real SQLite: the dose rows are identical and only
      // the status differs, so a booking that appears for the sold dog — or
      // fails to appear for the retired one — is the filter's own doing.
      final soldAnimal = await daos.animals.findById(animalId);
      await daos.animals.update(
        soldAnimal!.copyWith(status: AnimalStatus.sold),
        nowMs: 6,
      );
      final retiredId = await seedAnimal('Old Girl', AnimalStatus.retired);
      final retiredDoseId = await seedDoseFor(retiredId, dayAhead(20));
      final soldDoseId = await seedDoseFor(animalId, dayAhead(20));

      expect(await run(), 1);

      expect(writer.written.map((a) => a.title).toSet(), <String>{'Old Girl'});
      final booked = writer.written.map((a) => a.id).toSet();
      expect(
        booked,
        contains(notificationIdFor(retiredDoseId, ReminderKind.dueToday)),
      );
      for (final kind in ReminderKind.values) {
        expect(
          booked,
          isNot(contains(notificationIdFor(soldDoseId, kind))),
          reason: 'a sold dog\'s booster is someone else\'s 09:00',
        );
      }
    });
  });
}
