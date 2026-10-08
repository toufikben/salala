import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/core/utils/reminders.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';
import 'package:salala/presentation/screens/health_test_form_screen.dart';
import 'package:salala/presentation/screens/vaccination_form_screen.dart';
import 'package:salala/presentation/screens/vet_visit_form_screen.dart';
import 'package:salala/presentation/screens/weight_form_screen.dart';
import 'package:salala/presentation/widgets/animal_card.dart';

import '../helpers/fake_notification_writer.dart';
import '../helpers/pump_app.dart';

/// An animal with a fixed id: the record rows seed under it by foreign key, so
/// the test has to know the id it points at.
const String _nalaId = 'animal-nala';

Animal _nala() => Animal(
  id: _nalaId,
  name: 'Nala',
  species: 'dog',
  breed: 'Border collie',
  sex: Sex.female,
  status: AnimalStatus.active,
  isBreedingStock: true,
  birthDate: DateTime(2024, 5, 12).millisecondsSinceEpoch,
  createdAt: 0,
  updatedAt: 0,
);

Vaccination _dose({
  required String name,
  required int administered,
  int? nextDue,
}) => Vaccination(
  id: '',
  animalId: _nalaId,
  vaccineName: name,
  dateAdministered: administered,
  nextDueDate: nextDue,
  createdAt: 0,
  updatedAt: 0,
);

WeightEntry _weigh(int grams, int daysAgo) => WeightEntry(
  id: '',
  animalId: _nalaId,
  weightGrams: grams,
  measuredAt: _daysAgo(daysAgo),
);

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openNala(WidgetTester tester) async {
  // The card, not the name. An animal with a dose to book is named twice on the
  // home screen — once by the agenda above the herd, once by its own card — so an
  // unscoped `find.text('Nala')` answers with two rows and `tap()` cannot choose.
  await tester.tap(
    find.descendant(of: find.byType(AnimalCard), matching: find.text('Nala')),
  );
  await settleRealIo(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the ledger until a row of the weights section is on screen: the
/// ListView builds lazily, so a lower section does not exist yet. The scrollable
/// is taken from the detail screen itself rather than "the first on stage", so a
/// list still held by the router underneath cannot be scrolled by mistake.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.descendant(
      of: find.byType(AnimalDetailScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, 'Save');
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  // The row is written through SQLite and the section re-reads itself
  // afterwards, so one round of real waiting is not enough.
  await settleRealIo(tester);
  await settleRealIo(tester);
}

/// How many writer calls one save owes: `replace` clears the record's two ids
/// before writing, so two plus whatever alarms the due date still has ahead.
/// [waitForSchedulerCalls] waits for that many before the assertions run.
int _callsFor(int alarms) => 2 + alarms;

int _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

/// What a labelled field actually holds, which is the only way to prove a form
/// reopened prefilled rather than merely reopened.
String _fieldText(WidgetTester tester, String label) => tester
    .widget<TextFormField>(find.widgetWithText(TextFormField, label))
    .controller!
    .text;

int _daysAhead(int days) =>
    DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('an animal card opens its ledger', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);

    expect(find.text('Species: dog'), findsOneWidget);
    expect(find.text('Breed: Border collie'), findsOneWidget);
    expect(find.text('Dam: Not recorded'), findsOneWidget);

    // All four record sections are there, and each one is honestly empty. The
    // ledger is a lazy list, so a section is scrolled into view before it is
    // asserted rather than counted from the top of the screen.
    for (final title in const <String>[
      'Vaccinations',
      'Health tests',
      'Vet visits',
      'Weights',
    ]) {
      await _scrollTo(tester, find.text(title));
      expect(find.text(title), findsOneWidget);
      expect(find.text('Nothing recorded yet.'), findsWidgets);
    }
  });

  testWidgets('logging a vaccination writes the dose and shows it', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter();
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
    );
    await _openNala(tester);

    await _tap(tester, find.widgetWithText(TextButton, 'Add vaccination'));
    expect(find.text('Log a vaccination'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vaccine'),
      'DHPP',
    );
    await _save(tester);
    // The save always clears the record's two ids before writing, so two calls
    // is the proof it reached the scheduler; nothing more was written.
    await waitForSchedulerCalls(tester, notifications, _callsFor(0));

    expect(find.text('DHPP'), findsOneWidget);
    // A dose given today with no next-due date is not overdue.
    expect(find.text('Overdue'), findsNothing);

    // And it gets no alarm either: a reminder needs a date to be early about.
    expect(notifications.written, isEmpty);
  });

  testWidgets('saving a dose books its due morning on the phone', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter();
    // Twenty days out is inside the month-ahead window, so only the due morning
    // itself is still to come.
    final due = _daysAhead(20);
    final dueDay = dayFromMs(due)!;
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(name: 'Distemper', administered: _daysAgo(10), nextDue: due),
      ],
    );
    await _openNala(tester);

    await _tap(tester, find.text('Distemper'));
    await _save(tester);
    await waitForSchedulerCalls(tester, notifications, _callsFor(1));

    expect(notifications.written, hasLength(1));
    final alarm = notifications.written.single;
    // Titled with the animal, because a breeder with thirty dogs cannot act on a
    // message that says only that something is due.
    expect(alarm.title, 'Nala');
    expect(alarm.body, contains('Distemper'));
    expect(
      [alarm.at.year, alarm.at.month, alarm.at.day],
      [dueDay.year, dueDay.month, dueDay.day],
    );
    expect(alarm.at.hour, reminderHour);
    // The placeholders were filled before the copy left the app.
    expect(alarm.body, isNot(contains('{')));
  });

  testWidgets('a dose due further out is also announced a month ahead', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter();
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(
          name: 'Parvo',
          administered: _daysAgo(3),
          nextDue: _daysAhead(40),
        ),
      ],
    );
    await _openNala(tester);

    await _tap(tester, find.text('Parvo'));
    await _save(tester);
    await waitForSchedulerCalls(tester, notifications, _callsFor(2));

    expect(notifications.written, hasLength(2));
    final headsUp = notifications.written.first.at;
    final dueMorning = notifications.written.last.at;
    final daysApart = dueMorning.difference(headsUp).inDays;
    expect(daysApart, reminderLeadDays);
  });

  testWidgets('deleting a booked dose clears exactly the alarms it booked', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter();
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(
          name: 'Lepto',
          administered: _daysAgo(3),
          nextDue: _daysAhead(45),
        ),
      ],
    );
    await _openNala(tester);

    await _tap(tester, find.text('Lepto'));
    await _save(tester);
    await waitForSchedulerCalls(tester, notifications, _callsFor(2));
    // Saving clears the record's own ids before writing them again, so the ids
    // the alarms ended up under are known here.
    final booked = notifications.written.map((a) => a.id).toList();
    expect(booked, hasLength(2));

    await _tap(tester, find.text('Lepto'));
    await _tap(tester, find.byIcon(Icons.delete_outline));
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // Four calls from the booking just above, plus the delete's two clears and
    // no write of its own.
    await waitForSchedulerCalls(tester, notifications, 6);

    expect(find.text('Lepto'), findsNothing);
    // The row is gone, so an alarm for it would be a message about nothing — and
    // the delete reaches exactly the two alarms the booking wrote, no others.
    expect(
      notifications.cleared.sublist(notifications.cleared.length - 2),
      booked,
    );
  });

  testWidgets('a dose the phone will not remind about is still saved', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter()
      ..writeFailure = StateError('the notifier channel is closed');
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(
          name: 'Distemper',
          administered: _daysAgo(10),
          nextDue: _daysAhead(20),
        ),
      ],
    );
    await _openNala(tester);

    await _tap(tester, find.text('Distemper'));
    await _save(tester);
    // The two clears a replace always makes, then the write the phone refused.
    await waitForSchedulerCalls(tester, notifications, 2);
    await settleRealIo(tester);
    await settleRealIo(tester);

    // This is D33 seen from the other side: the dose was written by the
    // statement before the alarm, so a refused alarm is not a refused save. One
    // `try` around both would be sitting here on "nothing was written" over a
    // dose that is in the ledger — and the breeder would save it a second time.
    expect(find.byType(VaccinationFormScreen), findsNothing);
    expect(
      find.text('This could not be saved. Nothing was written.'),
      findsNothing,
    );
    // Not merely "no alarm was written" — the fake records the attempt before it
    // throws, so `written` alone would stay empty even if the form never reached
    // the alarm at all. These three calls are the proof it tried and swallowed
    // the refusal: a dose that landed, an alarm the phone would not take.
    expect(notifications.log, <String>['clear', 'clear', 'write']);
    expect(notifications.written, isEmpty);
    expect(find.text('Distemper'), findsOneWidget);
  });

  testWidgets('a dose the phone will not unremind is still deleted', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter()
      ..clearFailure = StateError('the notifier channel is closed');
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(
          name: 'Lepto',
          administered: _daysAgo(3),
          nextDue: _daysAhead(45),
        ),
      ],
    );
    await _openNala(tester);

    await _tap(tester, find.text('Lepto'));
    await _tap(tester, find.byIcon(Icons.delete_outline));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await waitForSchedulerCalls(tester, notifications, 1);
    await settleRealIo(tester);
    await settleRealIo(tester);

    // D34's other half: the row left on the statement before this one, so the
    // cancel the phone refused cannot be undone by retrying and is not a delete
    // that failed. A single `try` would hold the form open, on a dose that has
    // already gone, telling the breeder it is still there.
    expect(find.byType(VaccinationFormScreen), findsNothing);
    expect(
      find.text('This could not be deleted. The record is still there.'),
      findsNothing,
    );
    expect(find.text('Lepto'), findsNothing);
    // The row went first, so the cancel the phone refused is the only call this
    // screen ever made — and it refused on the first of the two.
    expect(notifications.log, <String>['clear']);
    expect(notifications.cleared, isEmpty);
  });

  testWidgets('a dose whose due date passed is badged overdue', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(
          name: 'Rabies',
          administered: _daysAgo(100),
          nextDue: _daysAgo(4),
        ),
        _dose(
          name: 'Distemper',
          administered: _daysAgo(10),
          nextDue: _daysAhead(20),
        ),
      ],
    );
    await _openNala(tester);

    expect(find.text('Rabies'), findsOneWidget);
    expect(find.text('Distemper'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('a dose is correctable from its own row', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(name: 'DHPP', administered: _daysAgo(30)),
      ],
    );
    await _openNala(tester);

    await _tap(tester, find.text('DHPP'));
    expect(find.text('Edit vaccination'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vaccine'),
      'DHPP + Lepto',
    );
    await _save(tester);

    expect(find.text('DHPP + Lepto'), findsOneWidget);
  });

  testWidgets('a weigh-in is typed in kilograms and shown in kilograms', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);

    // The symptoms section sits above the weights one, so the weights button is
    // below the fold and the lazy list has not built it yet.
    await _scrollTo(tester, find.widgetWithText(TextButton, 'Add weight'));
    await _tap(tester, find.widgetWithText(TextButton, 'Add weight'));
    // The form is the only place a breeder looks for an edit that does not
    // exist, so it has to say the weigh-in is append-only.
    expect(
      find.text(
        "Weigh-ins are never edited. Measured wrong? Delete it and weigh again.",
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Weight (kg)'),
      '4.2',
    );
    await _save(tester);

    expect(find.text('4.20 kg'), findsOneWidget);
  });

  testWidgets('a puppy under a kilogram is shown in grams, newest first', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedWeights: <WeightEntry>[_weigh(300, 9), _weigh(4200, 2)],
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('300 g'));

    expect(find.text('300 g'), findsOneWidget);
    expect(find.text('4.20 kg'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('4.20 kg')).dy,
      lessThan(tester.getTopLeft(find.text('300 g')).dy),
    );
  });

  testWidgets('deleting a weigh-in leaves the rest of the curve', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedWeights: <WeightEntry>[_weigh(300, 9), _weigh(4200, 2)],
    );
    await _openNala(tester);

    // The newest weigh-in is the first row, and the only control it gets is a
    // delete: a weigh-in is never edited, it is removed and measured again.
    // Scroll to the row's own text, not to the delete icon: both weigh-ins are
    // on screen by the time the scroll ends, and scrollUntilVisible finishes by
    // asking for the single element it was given. Two icons, one answer.
    await _scrollTo(tester, find.text('4.20 kg'));
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRealIo(tester);
    await settleRealIo(tester);

    expect(find.text('4.20 kg'), findsNothing);
    expect(find.text('300 g'), findsOneWidget);
  });

  testWidgets('a screening whose certificate lapsed is badged expired', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedHealthTests: <HealthTest>[
        _screening('BAER', result: 'Clear', tested: 400, validUntil: 10),
        _screening('OFA hips', result: 'Good', tested: 200, validUntil: -60),
      ],
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('OFA hips'));

    expect(find.text('OFA hips'), findsOneWidget);
    // Only the lapsed one is flagged; a permanent OFA grade is not a claim
    // running out.
    expect(find.text('Expired'), findsOneWidget);
    await _scrollTo(tester, find.text('BAER'));
    expect(find.text('BAER'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('logging a screening writes the row', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);
    await _scrollTo(tester, find.text('Health tests'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add test'));
    expect(find.text('Log a health test'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Screening'),
      'Echocardiography',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Result'),
      'Normal',
    );
    await _save(tester);

    expect(find.text('Echocardiography'), findsOneWidget);
    expect(find.textContaining('Normal'), findsWidgets);
  });

  testWidgets('a screening without a result is refused', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);
    await _scrollTo(tester, find.text('Health tests'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add test'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Screening'),
      'BAER',
    );
    await _save(tester);

    expect(find.text('Enter the result'), findsOneWidget);
    // Still on the form. The typed name is sitting in the field, so asserting
    // the row is absent would prove nothing — the route not popping is the
    // evidence that nothing was written.
    expect(find.text('Log a health test'), findsOneWidget);

    // Adding the missing result now lets the very same save through, which
    // shows the refusal was about the result and not a broken form.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Result'),
      'Clear',
    );
    await _save(tester);

    expect(find.text('Log a health test'), findsNothing);
    await _scrollTo(tester, find.text('BAER'));
    expect(find.text('BAER'), findsOneWidget);
  });

  testWidgets('a screening is correctable from its own row', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedHealthTests: <HealthTest>[
        _screening('OFA hips', result: 'Good', tested: 30),
      ],
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('OFA hips'));

    await _tap(tester, find.text('OFA hips'));
    expect(find.text('Edit health test'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Result'),
      'Excellent',
    );
    await _save(tester);

    expect(find.textContaining('Excellent'), findsWidgets);
  });

  testWidgets('a screening deleted from its edit screen leaves the ledger', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedHealthTests: <HealthTest>[
        _screening('BAER', result: 'Clear', tested: 30),
        _screening('OFA hips', result: 'Good', tested: 40),
      ],
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('BAER'));

    await _tap(tester, find.text('BAER'));
    await _tap(tester, find.byIcon(Icons.delete_outline));
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRealIo(tester);
    await settleRealIo(tester);

    expect(find.text('BAER'), findsNothing);
    expect(find.text('OFA hips'), findsOneWidget);
  });

  testWidgets('a vet visit logs the reason and keeps the cost as typed', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);
    await _scrollTo(tester, find.text('Vet visits'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add visit'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Limping on the left fore',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost'),
      '250.50',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Currency'),
      'mad',
    );
    await _save(tester);

    expect(find.text('Limping on the left fore'), findsOneWidget);

    // Reopening it proves the amount survived the round trip through SQLite and
    // that the currency was normalised to a code, not left as typed.
    await _tap(tester, find.text('Limping on the left fore'));
    expect(find.text('Edit vet visit'), findsOneWidget);
    expect(_fieldText(tester, 'Cost'), '250.5');
    expect(_fieldText(tester, 'Currency'), 'MAD');
  });

  testWidgets('a visit with no reason is titled by the clinic that saw it', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedVisits: <VetVisit>[
        VetVisit(
          id: '',
          animalId: _nalaId,
          visitDate: _daysAgo(5),
          clinicName: 'Atlas Veterinary',
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('Atlas Veterinary'));

    expect(find.text('Atlas Veterinary'), findsOneWidget);
  });

  testWidgets('the ledger keeps its section order in Arabic', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_nala()],
      seedHealthTests: <HealthTest>[
        _screening('OFA hips', result: 'Good', tested: 30),
      ],
      seedVisits: <VetVisit>[
        VetVisit(
          id: '',
          animalId: _nalaId,
          visitDate: _daysAgo(5),
          reason: 'عرج',
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );
    await _openNala(tester);

    // Each finder is scrolled to before it is asserted: the ledger is lazy, and
    // a row above the fold has already been dropped by the time the next one is
    // reached.
    await _scrollTo(tester, find.text('فحوصات الصحة'));
    expect(find.text('فحوصات الصحة'), findsOneWidget);
    await _scrollTo(tester, find.text('OFA hips'));
    expect(find.text('OFA hips'), findsOneWidget);
    await _scrollTo(tester, find.text('عرج'));
    expect(find.text('عرج'), findsOneWidget);
  });

  testWidgets(
    'a dose the database refuses keeps the form open and the button live',
    (tester) async {
      _usePhoneViewport(tester);
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        seed: <Animal>[_nala()],
        beforeLaunch: refuseWritesTo('vaccinations'),
      );
      await _openNala(tester);

      await _tap(tester, find.widgetWithText(TextButton, 'Add vaccination'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vaccine'),
        'DHPP',
      );

      await tapSaveAndGetAnswer(tester);

      // The route did not pop, the field still holds the breeder's word, and the
      // button is not a spinner: a dose SQLite refused stays the form's to keep
      // open, rather than freezing on a save that will never answer. The alarm is
      // booked once the row exists, so a refused write owes none.
      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(VaccinationFormScreen),
        label: 'Vaccine',
        text: 'DHPP',
        notifications: notifications,
      );
    },
  );

  testWidgets(
    'a dose the database refuses to delete keeps its row and its alarm',
    (tester) async {
      _usePhoneViewport(tester);
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        resyncOnLaunch: true,
        seed: <Animal>[_nala()],
        seedVaccinations: <Vaccination>[
          _dose(
            name: 'DHPP',
            administered: _daysAgo(30),
            nextDue: _daysAhead(20),
          ),
        ],
        beforeLaunch: refuseDeletesOf('vaccinations'),
      );
      // The launch booked this dose's due morning, so there is an alarm in the
      // phone for the refused delete to leave alone. On a dose with no due date
      // the log would read empty whatever the code did.
      await waitForSchedulerCalls(tester, notifications, _callsFor(1));
      expect(notifications.written, hasLength(1));
      final booked = notifications.log.length;

      await _openNala(tester);
      await _scrollTo(tester, find.text('DHPP'));

      await _tap(tester, find.text('DHPP'));
      await _tap(tester, find.byIcon(Icons.delete_outline));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settleRefusal(tester);

      // The form stayed open on a dose that is still in the ledger, and nothing
      // was handed to the alarm manager: a row that survived keeps its reminder,
      // which is the half of this path a silent failure would have got wrong.
      expect(
        find.text('This could not be deleted. The record is still there.'),
        findsOneWidget,
      );
      expect(find.byType(VaccinationFormScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Vaccine'),
            )
            .controller!
            .text,
        'DHPP',
      );
      expect(notifications.log, hasLength(booked));
      expect(notifications.written, hasLength(1));
    },
  );

  testWidgets('a dose due before the day it was given is refused before the ledger is '
      'touched', (tester) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter();
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        // A row that cannot have happened, written through the shipped dao:
        // nothing in the write path checks the pair, so this is exactly what a
        // restored pack or an older build leaves behind. Editing it is the way
        // a breeder finds out.
        _dose(name: 'DHPP', administered: _daysAgo(30), nextDue: _daysAgo(60)),
      ],
      beforeLaunch: refuseUpdatesOf('vaccinations'),
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('DHPP'));
    await _tap(tester, find.text('DHPP'));

    await tapSaveAndGetAnswer(tester);

    expect(
      find.text('The next dose is due before this dose was given.'),
      findsOneWidget,
    );
    expect(
      find.text('This could not be saved. Nothing was written.'),
      findsNothing,
      reason:
          'the trigger this test installs is what turns that absence into '
          'evidence: had the form reached SQLite with these dates, the '
          'database would have refused and this is the sentence it refused '
          'with — see the test below for the same refusal on a legal pair',
    );
    expect(find.byType(VaccinationFormScreen), findsOneWidget);
    // No alarm for a dose that was never saved, and none for a due date that
    // is behind the dose: the form stopped before either half ran.
    expect(notifications.log, isEmpty);
  });

  testWidgets('a dose with its dates in order does reach the ledger, and the ledger is '
      'what answers', (tester) async {
    _usePhoneViewport(tester);
    final notifications = FakeNotificationWriter();
    await pumpSalala(
      tester,
      notifications: notifications,
      seed: <Animal>[_nala()],
      seedVaccinations: <Vaccination>[
        _dose(
          name: 'DHPP',
          administered: _daysAgo(30),
          nextDue: _daysAhead(20),
        ),
      ],
      beforeLaunch: refuseUpdatesOf('vaccinations'),
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('DHPP'));
    await _tap(tester, find.text('DHPP'));

    await tapSaveAndGetAnswer(tester);

    // One field apart from the test above, and the sentence is the database's
    // instead: so the refusal above really did stop at the dates, and an edit
    // of a legal dose still goes through to SQLite and keeps the form open when
    // SQLite says no.
    expectRefusedWrite(
      tester,
      stillOnScreen: find.byType(VaccinationFormScreen),
      label: 'Vaccine',
      text: 'DHPP',
      notifications: notifications,
    );
    expect(
      find.text('The next dose is due before this dose was given.'),
      findsNothing,
    );
  });

  testWidgets(
    'a screening the database refuses keeps the form open and the button live',
    (tester) async {
      _usePhoneViewport(tester);
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        seed: <Animal>[_nala()],
        beforeLaunch: refuseWritesTo('health_tests'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Health tests'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add test'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Screening'),
        'Echocardiography',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Result'),
        'Normal',
      );

      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(HealthTestFormScreen),
        label: 'Screening',
        text: 'Echocardiography',
        notifications: notifications,
      );
    },
  );

  testWidgets(
    'a visit the database refuses keeps the form open and the button live',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala()],
        beforeLaunch: refuseWritesTo('vet_visits'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Vet visits'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add visit'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'),
        'Limping on the left fore',
      );

      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(VetVisitFormScreen),
        label: 'Reason',
        text: 'Limping on the left fore',
      );
    },
  );

  testWidgets(
    'a weigh-in the database refuses keeps the form open and the button live',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala()],
        beforeLaunch: refuseWritesTo('weight_entries'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.widgetWithText(TextButton, 'Add weight'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add weight'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Weight (kg)'),
        '4.2',
      );

      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(WeightFormScreen),
        label: 'Weight (kg)',
        text: '4.2',
      );
    },
  );

  // The four tests below are the same rule at four different forms, and each one
  // is a pair inside itself: it refuses the impossible day, then the very same
  // form accepts a legal one and the trigger it is sitting on bites. Without that
  // second half the first half proves nothing — an absent sentence about the
  // database is also what a test with no trigger looks like.
  //
  // Every date here is said relative to the run's own today, because a fixed
  // "12 May 2024" birthday stops being reachable by a five-year picker window as
  // the years pass, and a test that only works this decade is a test waiting to
  // fail for a reason that has nothing to do with the app.

  testWidgets(
    'a weigh-in dated before the animal was born is refused, and the same form '
    'on a day after the birth does reach the ledger',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala().copyWith(birthDate: _daysAgo(400))],
        beforeLaunch: refuseWritesTo('weight_entries'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.widgetWithText(TextButton, 'Add weight'));
      await _tap(tester, find.widgetWithText(TextButton, 'Add weight'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Weight (kg)'),
        '1.8',
      );
      await typeDateIntoPicker(
        tester,
        scope: WeightFormScreen,
        tile: 0,
        usDay: usDay(_daysAgo(500)),
      );

      await tapSaveAndGetAnswer(tester);

      expect(
        find.text('This date is before this animal was born.'),
        findsOneWidget,
      );
      expect(
        find.text('This could not be saved. Nothing was written.'),
        findsNothing,
        reason:
            'a weigh-in is append-only, so the insert trigger is the whole of '
            'the evidence that nothing was written — and the legal day at the '
            'end of this test is what shows that trigger is live',
      );
      expect(find.byType(WeightFormScreen), findsOneWidget);

      await dismissRefusals(tester);
      await typeDateIntoPicker(
        tester,
        scope: WeightFormScreen,
        tile: 0,
        usDay: usDay(_daysAgo(300)),
      );
      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(WeightFormScreen),
        label: 'Weight (kg)',
        text: '1.8',
      );
    },
  );

  testWidgets(
    'a dose on a row that predates the animal is refused on the edit, and the '
    'same edit with a legal day does reach the ledger',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala().copyWith(birthDate: _daysAgo(1000))],
        seedVaccinations: <Vaccination>[
          // A row the write path lets exist: it came in with a pack, or with a
          // build from before this rule. Opening it to fix the vaccine name is
          // how a breeder finds out the day is wrong.
          _dose(name: 'DHPP', administered: _daysAgo(1200)),
        ],
        beforeLaunch: refuseUpdatesOf('vaccinations'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('DHPP'));
      await _tap(tester, find.text('DHPP'));

      await tapSaveAndGetAnswer(tester);

      expect(
        find.text('This date is before this animal was born.'),
        findsOneWidget,
      );
      expect(
        find.text('This could not be saved. Nothing was written.'),
        findsNothing,
        reason:
            'the dose is edited with an UPDATE, not an INSERT, which is why '
            'this test installs the update trigger: the sentence below is what '
            'SQLite itself says when a row does reach it',
      );

      await dismissRefusals(tester);
      await typeDateIntoPicker(
        tester,
        scope: VaccinationFormScreen,
        tile: 0,
        usDay: usDay(_daysAgo(900)),
      );
      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(VaccinationFormScreen),
        label: 'Vaccine',
        text: 'DHPP',
      );
    },
  );

  testWidgets('a screening dated before the animal was born is refused on the edit, and a '
      'legal day on the same screening is SQLite\'s to refuse', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala().copyWith(birthDate: _daysAgo(1000))],
      seedHealthTests: <HealthTest>[
        _screening('OFA hips', result: 'Good', tested: 1200),
      ],
      beforeLaunch: refuseUpdatesOf('health_tests'),
    );
    await _openNala(tester);
    await _scrollTo(tester, find.text('OFA hips'));
    await _tap(tester, find.text('OFA hips'));

    await tapSaveAndGetAnswer(tester);

    expect(
      find.text('This date is before this animal was born.'),
      findsOneWidget,
    );
    expect(
      find.text('This could not be saved. Nothing was written.'),
      findsNothing,
      reason: 'see the dose test above: same trigger kind, same pairing',
    );

    await dismissRefusals(tester);
    await typeDateIntoPicker(
      tester,
      scope: HealthTestFormScreen,
      tile: 0,
      usDay: usDay(_daysAgo(900)),
    );
    await tapSaveAndGetAnswer(tester);

    expectRefusedWrite(
      tester,
      stillOnScreen: find.byType(HealthTestFormScreen),
      label: 'Screening',
      text: 'OFA hips',
    );
  });

  testWidgets(
    'a visit dated before the animal was born is refused on the edit, and a '
    'legal day on the same visit is SQLite\'s to refuse',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala().copyWith(birthDate: _daysAgo(1000))],
        seedVisits: <VetVisit>[
          VetVisit(
            id: '',
            animalId: _nalaId,
            visitDate: _daysAgo(1200),
            clinicName: 'Atlas Veterinary',
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
        beforeLaunch: refuseUpdatesOf('vet_visits'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Atlas Veterinary'));
      await _tap(tester, find.text('Atlas Veterinary'));

      await tapSaveAndGetAnswer(tester);

      expect(
        find.text('This date is before this animal was born.'),
        findsOneWidget,
      );
      expect(
        find.text('This could not be saved. Nothing was written.'),
        findsNothing,
        reason: 'see the dose test above: same trigger kind, same pairing',
      );

      await dismissRefusals(tester);
      await typeDateIntoPicker(
        tester,
        scope: VetVisitFormScreen,
        tile: 0,
        usDay: usDay(_daysAgo(900)),
      );
      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(VetVisitFormScreen),
        label: 'Clinic',
        text: 'Atlas Veterinary',
      );
    },
  );
}

/// A screening dated `tested` days ago, optionally expiring `validUntil` days
/// from now (negative means it lapsed that many days ago).
HealthTest _screening(
  String type, {
  required String result,
  required int tested,
  int? validUntil,
}) => HealthTest(
  id: '',
  animalId: _nalaId,
  testType: type,
  result: result,
  testDate: _daysAgo(tested),
  validUntil: validUntil == null ? null : _daysAhead(validUntil),
  createdAt: 0,
  updatedAt: 0,
);
