import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';

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
  await tester.tap(find.text('Nala'));
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

int _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

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

    // Both record sections are there, and both are honestly empty.
    expect(find.text('Vaccinations'), findsOneWidget);
    expect(find.text('Weights'), findsOneWidget);
    expect(find.text('Nothing recorded yet.'), findsNWidgets(2));
  });

  testWidgets('logging a vaccination writes the dose and shows it', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);

    await _tap(tester, find.widgetWithText(TextButton, 'Add vaccination'));
    expect(find.text('Log a vaccination'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vaccine'),
      'DHPP',
    );
    await _save(tester);

    expect(find.text('DHPP'), findsOneWidget);
    // A dose given today with no next-due date is not overdue.
    expect(find.text('Overdue'), findsNothing);
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

    await _tap(tester, find.widgetWithText(TextButton, 'Add weight'));
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
    await _scrollTo(tester, find.byIcon(Icons.delete_outline).first);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRealIo(tester);
    await settleRealIo(tester);

    expect(find.text('4.20 kg'), findsNothing);
    expect(find.text('300 g'), findsOneWidget);
  });
}
