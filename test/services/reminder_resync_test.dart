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

  group('staleRecordIds', () {
    test('the records the herd map drops are named for cancelling, in the same walk', () {
      // The two halves of one loop, asserted together: `bookingsFor` refusing a
      // sold dog's dose is not the same thing as taking her alarm out of the
      // phone, and the device showed the difference (a 09:00 message for a dog at
      // another address). A record missing from the bookings is only harmless if
      // something here still names it.
      final doses = <Vaccination>[
        dose(id: 'dose-away', animalId: 'sold-1', dueMs: dayAhead(20)),
        dose(id: 'dose-home', dueMs: dayAhead(20)),
      ];
      final herd = const <String, String>{'animal-1': 'Nala'};

      final bookings = bookingsFor(
        doses: doses,
        screenings: const <HealthTest>[],
        herd: herd,
        dueDayText: stampedDay,
        now: noon,
      );

      expect(bookings.map((b) => b.recordId), <String>['dose-home']);
      expect(
        staleRecordIds(
          doses: doses,
          screenings: const <HealthTest>[],
          herd: herd,
          now: noon,
        ),
        <String>['dose-away'],
      );
    });

    test('a record with nothing ahead of it is neither booked nor stale', () {
      // The overdue half is the absence, so the same test carries the day that
      // still has a morning coming: without the pair this says nothing about
      // which of the two rules made the list empty.
      List<String> stale(int dueMs) => staleRecordIds(
        doses: <Vaccination>[dose(animalId: 'gone', dueMs: dueMs)],
        screenings: const <HealthTest>[],
        herd: const <String, String>{},
        now: noon,
      );

      expect(stale(dayAhead(-3)), isEmpty);
      expect(stale(dayAhead(3)), hasLength(1));
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

    test(
      'a launch takes a sold dog\'s already-booked dose out of the phone',
      () async {
        // The same walk as the test above, read the other way round: not "was
        // this re-booked?" but "is the phone still holding it?". The launch is the
        // self-healing half — an app killed before its edit could finish leaves
        // the booking in the plugin's own list, and only a launch that clears what
        // the herd map dropped can take it back.
        final soldDoseId = await seedDose(dayAhead(20));
        final sold = (await daos.animals.findById(animalId))!;
        await daos.animals.update(
          sold.copyWith(status: AnimalStatus.sold),
          nowMs: 6,
        );
        final retiredId = await seedAnimal('Old Girl', AnimalStatus.retired);
        final retiredDoseId = await seedDoseFor(retiredId, dayAhead(20));

        expect(await run(), 1);

        // The retired dam's morning is still written: dropping a booking nobody
        // owns must not become a way to lose one the breeder still owes.
        expect(writer.written, hasLength(1));
        expect(writer.written.single.title, 'Old Girl');
        expect(
          writer.cleared,
          containsAll(<int>[
            notificationIdFor(soldDoseId, ReminderKind.headsUp),
            notificationIdFor(soldDoseId, ReminderKind.dueToday),
          ]),
        );
        expect(
          writer.written.map((a) => a.id),
          isNot(contains(notificationIdFor(soldDoseId, ReminderKind.dueToday))),
        );
        expect(
          writer.cleared,
          contains(notificationIdFor(retiredDoseId, ReminderKind.headsUp)),
          reason:
              'a re-book clears its own ids first, so both records are named',
        );
      },
    );
  });

  group('resyncAnimalReminders', () {
    late Daos daos;
    late FakeNotificationWriter writer;
    late ReminderScheduler scheduler;
    late AppLocalizations l10n;
    late String animalId;

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

    Future<String> seedDose(int? dueMs) async =>
        (await daos.vaccinations.create(
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
        )).id;

    /// The form's own write: the row goes back with a new status, and nothing
    /// else in the app is asked to notice.
    Future<void> setStatus(AnimalStatus status) async {
      final animal = await daos.animals.findById(animalId);
      await daos.animals.update(animal!.copyWith(status: status), nowMs: 3);
    }

    Future<int> reconcile() => resyncAnimalReminders(
      scheduler,
      daos: daos,
      animalId: animalId,
      l10n: l10n,
      dueDayText: dayText,
      now: noon,
    );

    Future<int> launch() => resyncReminders(
      scheduler,
      daos: daos,
      l10n: l10n,
      dueDayText: dayText,
      now: noon,
    );

    test('an animal marked Placed loses the alarm the launch booked', () async {
      final doseId = await seedDose(dayAhead(20));
      expect(await launch(), 1);
      expect(writer.log, <String>['clear', 'clear', 'write']);

      await setStatus(AnimalStatus.sold);
      expect(await reconcile(), 0);

      // The two ids the launch had just been handed, taken back out in the same
      // order the plugin was given them, and no write behind them.
      expect(writer.log, <String>['clear', 'clear', 'write', 'clear', 'clear']);
      expect(writer.cleared.sublist(2), <int>[
        notificationIdFor(doseId, ReminderKind.headsUp),
        notificationIdFor(doseId, ReminderKind.dueToday),
      ]);
      expect(
        writer.written,
        hasLength(1),
        reason: 'a dose of a dog who left is nobody\'s 09:00',
      );
    });

    test('a dose beyond the launch horizon is taken out by the animal that goes', () async {
      // Why this path reads the animal's own rows instead of reusing the
      // horizon query: the form books a dose as far ahead as it is dated, while
      // the launch only asks for the next 45 days. A dose 75 days out is
      // invisible to a launch, so a launch-only rule would leave it booked for
      // as long as the animal stays sold.
      final doseId = await seedDose(dayAhead(reminderHorizonDays + 30));
      expect(await launch(), 0);
      expect(writer.log, isEmpty);

      await setStatus(AnimalStatus.sold);
      expect(await reconcile(), 0);

      expect(writer.cleared, <int>[
        notificationIdFor(doseId, ReminderKind.headsUp),
        notificationIdFor(doseId, ReminderKind.dueToday),
      ]);
    });

    test('an animal brought back to the herd is booked again', () async {
      final doseId = await seedDose(dayAhead(20));

      await setStatus(AnimalStatus.sold);
      expect(await reconcile(), 0);
      expect(writer.written, isEmpty);

      await setStatus(AnimalStatus.active);
      expect(await reconcile(), 1);

      expect(writer.log, <String>['clear', 'clear', 'clear', 'clear', 'write']);
      expect(writer.written.single.title, 'Nala');
      expect(
        writer.written.single.id,
        notificationIdFor(doseId, ReminderKind.dueToday),
      );
    });

    test('a dam edited to retired keeps her booked morning', () async {
      // D40 at the edit path: `retired` is a word about the breeding plan, so
      // editing her out of the whelping box must not silence the shot she still
      // needs in the house. The pair of the test above that empties the phone.
      final doseId = await seedDose(dayAhead(20));

      await setStatus(AnimalStatus.retired);
      expect(await reconcile(), 1);

      expect(writer.log, <String>['clear', 'clear', 'write']);
      expect(writer.written.single.title, 'Nala');
      expect(
        writer.written.single.id,
        notificationIdFor(doseId, ReminderKind.dueToday),
      );
    });
  });
}
