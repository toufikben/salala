import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';

import '../helpers/pump_app.dart';

const int _day = 86400000;

const String _nalaId = 'animal-nala';
const String _zeusId = 'animal-zeus';

int _daysFromNow(int days) =>
    DateTime.now().toUtc().millisecondsSinceEpoch + days * _day;

Animal _animal(
  String id, {
  required String name,
  AnimalStatus status = AnimalStatus.active,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: status,
  createdAt: 0,
  updatedAt: 0,
);

/// A dose whose next one falls [dueInDays] from now — negative for a booking
/// whose morning has already gone.
Vaccination _dose({
  required String animalId,
  String name = 'Rabies',
  required int dueInDays,
}) => Vaccination(
  id: '',
  animalId: animalId,
  vaccineName: name,
  dateAdministered: _daysFromNow(dueInDays - 30),
  nextDueDate: _daysFromNow(dueInDays),
  createdAt: 0,
  updatedAt: 0,
);

Vaccination _noBookingDose(String animalId) => Vaccination(
  id: '',
  animalId: animalId,
  vaccineName: 'Rabies',
  dateAdministered: _daysFromNow(-30),
  createdAt: 0,
  updatedAt: 0,
);

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The agenda row for a given dose sentence, so a tap cannot land on the
/// animal's own card, which carries the same name.
Finder _agendaRow(String sentence) =>
    find.ancestor(of: find.text(sentence), matching: find.byType(ListTile));

Future<void> _scrollLedgerTo(WidgetTester tester, Finder finder) async {
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

void main() {
  // A tap that misses its widget must fail the test rather than only warn
  // (D12) — this screen has two finders per animal name, so it can go wrong.
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('an overdue dose is on the home screen, above the herd', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, name: 'Nala')],
      seedVaccinations: <Vaccination>[_dose(animalId: _nalaId, dueInDays: -3)],
    );

    expect(find.text('Vaccinations to book'), findsOneWidget);
    expect(find.text('Rabies was due 3 days ago'), findsOneWidget);

    // Above the animals: the screen opens on what has to be done, and the herd
    // it is about is below it rather than off to the right of a tap.
    expect(
      tester.getTopLeft(find.text('Vaccinations to book')).dy,
      lessThan(tester.getTopLeft(find.text('All animals')).dy),
    );
  });

  testWidgets('a dose due inside the fortnight is listed with its count', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, name: 'Nala')],
      seedVaccinations: <Vaccination>[_dose(animalId: _nalaId, dueInDays: 5)],
    );

    expect(find.text('Rabies is due in 5 days'), findsOneWidget);
    expect(find.text('Rabies was due 3 days ago'), findsNothing);
  });

  testWidgets('a dose due after the fortnight is not booked yet', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, name: 'Nala')],
      seedVaccinations: <Vaccination>[_dose(animalId: _nalaId, dueInDays: 20)],
    );

    // Nothing at all, not an empty card: an herd with nothing to book and an
    // agenda that has not loaded yet must both leave the page as it was.
    expect(find.text('Vaccinations to book'), findsNothing);
    expect(find.bySubtype<ProgressIndicator>(), findsNothing);
  });

  testWidgets('a dose with no next date is not a booking', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, name: 'Nala')],
      seedVaccinations: <Vaccination>[_noBookingDose(_nalaId)],
    );

    expect(find.text('Vaccinations to book'), findsNothing);
    expect(find.text('Nala'), findsOneWidget);
  });

  testWidgets('an animal that was sold comes off the agenda', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal(_nalaId, name: 'Nala'),
        _animal(_zeusId, name: 'Zeus', status: AnimalStatus.sold),
      ],
      seedVaccinations: <Vaccination>[
        _dose(animalId: _nalaId, name: 'Rabies', dueInDays: -3),
        _dose(animalId: _zeusId, name: 'Distemper', dueInDays: -1),
      ],
    );

    expect(find.text('Distemper was due 1 day ago'), findsNothing);
    expect(find.text('Rabies was due 3 days ago'), findsOneWidget);
    // Zeus is still an animal in the ledger — only his bookings are gone.
    expect(find.text('Zeus'), findsOneWidget);
  });

  testWidgets('two animals, two rows, the later booking on top', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal(_nalaId, name: 'Nala'),
        _animal(_zeusId, name: 'Zeus'),
      ],
      seedVaccinations: <Vaccination>[
        _dose(animalId: _nalaId, name: 'Rabies', dueInDays: 6),
        _dose(animalId: _zeusId, name: 'Distemper', dueInDays: -2),
      ],
    );

    expect(
      tester.getTopLeft(find.text('Distemper was due 2 days ago')).dy,
      lessThan(tester.getTopLeft(find.text('Rabies is due in 6 days')).dy),
    );
  });

  testWidgets("tapping a row opens that animal's ledger", (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal(_nalaId, name: 'Nala'),
        _animal(_zeusId, name: 'Zeus'),
      ],
      seedVaccinations: <Vaccination>[
        _dose(animalId: _nalaId, name: 'Rabies', dueInDays: -3),
        _dose(animalId: _zeusId, name: 'Distemper', dueInDays: -1),
      ],
    );

    // The row that names Zeus is tapped, and it is Zeus's ledger that opens:
    // `animalId` on the row is what the tap uses, so a swapped id would show up
    // here as the wrong animal's sections.
    await tester.tap(_agendaRow('Distemper was due 1 day ago'));
    await settleRealIo(tester);

    expect(find.widgetWithText(AppBar, 'Zeus'), findsOneWidget);
  });

  testWidgets('deleting the dose takes the animal off the agenda', (
    tester,
  ) async {
    // The invalidation is the feature. Without `ref.invalidate(agendaDosesProvider)`
    // in `deleteVaccination`, the home screen behind keeps the row and tells the
    // breeder to book a shot that is no longer in the database — and nothing else
    // on the way back would notice, because the list was never rebuilt.
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, name: 'Nala')],
      seedVaccinations: <Vaccination>[_dose(animalId: _nalaId, dueInDays: -3)],
    );
    expect(find.text('Rabies was due 3 days ago'), findsOneWidget);

    await tester.tap(_agendaRow('Rabies was due 3 days ago'));
    await settleRealIo(tester);

    await _scrollLedgerTo(tester, find.text('Rabies'));
    await tester.tap(find.text('Rabies'));
    await settleRealIo(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRealIo(tester);
    await settleRealIo(tester);

    // Back on the herd: the dose is gone from the ledger and from the agenda,
    // and the animal is still there.
    await tester.pageBack();
    await settleRealIo(tester);

    expect(find.text('Vaccinations to book'), findsNothing);
    expect(find.text('Rabies was due 3 days ago'), findsNothing);
    expect(find.text('Nala'), findsOneWidget);
  });

  testWidgets('the agenda speaks Arabic, with Latin digits', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_animal(_nalaId, name: 'Nala')],
      seedVaccinations: <Vaccination>[_dose(animalId: _nalaId, dueInDays: -3)],
    );

    expect(find.text('تلقيحات يجب حجزها'), findsOneWidget);
    // D21: the count is Latin even inside the Arabic sentence, and three takes
    // the plural form rather than the dual or the singular.
    expect(find.text('Rabies كان مستحقًا منذ 3 أيام'), findsOneWidget);
  });
}
