import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/presentation/widgets/animal_card.dart';

import '../helpers/pump_app.dart';

/// The search box on the home screen, as a breeder uses it.
///
/// The matching rules are pinned in `test/core/herd_search_test.dart`; this file
/// is about the wiring, which is where a search quietly stops working: a filter
/// that reads the database per keystroke, an agenda that keeps answering for the
/// whole herd while the list under it shows one animal, a box nobody can empty.
const String _nalaId = 'animal-nala';

Animal _animal(
  String id, {
  required String name,
  bool breeding = false,
  String? microchipId,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  isBreedingStock: breeding,
  microchipId: microchipId,
  createdAt: 0,
  updatedAt: 0,
);

Vaccination _overdueDose() => Vaccination(
  id: '',
  animalId: _nalaId,
  vaccineName: 'Rabies',
  dateAdministered: DateTime.now()
      .subtract(const Duration(days: 40))
      .millisecondsSinceEpoch,
  nextDueDate: DateTime.now()
      .subtract(const Duration(days: 3))
      .millisecondsSinceEpoch,
  createdAt: 0,
  updatedAt: 0,
);

/// The field lives in the app bar, and this screen has no other one, so it is
/// found by type. A second `TextField` on the home screen would make every test
/// below ambiguous rather than wrong, which is worth knowing on its own.
final Finder _searchField = find.byType(TextField);

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // A tap that misses its widget must fail the test rather than only warn (D12).
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('the box narrows the herd to the animals that answer it', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal('a-1', name: 'Bella'),
        _animal('a-2', name: 'Zeus', breeding: true),
      ],
    );

    expect(find.text('Bella'), findsOneWidget);
    expect(find.text('Zeus'), findsOneWidget);

    await tester.enterText(_searchField, 'zeu');
    await tester.pump();

    expect(find.text('Zeus'), findsOneWidget);
    expect(find.text('Bella'), findsNothing);
    // The sections give shape to everything a breeder owns. A search asked a
    // different question, so the answer is one ranked list with no header over
    // it — a breeding block printed first would otherwise outrank the match
    // strength that `searchHerd` had just computed.
    expect(find.text('Breeding stock'), findsNothing);
    expect(find.text('All animals'), findsNothing);
  });

  testWidgets('a search keeps the order the matches were ranked in', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        // The weaker match is the breeding animal on purpose: the herd view puts
        // that block first, and a search must not.
        _animal('a-1', name: 'Zidane', breeding: true),
        _animal('a-2', name: 'Zid'),
      ],
    );

    await tester.enterText(_searchField, 'zid');
    await tester.pump();

    expect(
      tester
          .widgetList<AnimalCard>(find.byType(AnimalCard))
          .map((AnimalCard card) => card.animal.name)
          .toList(),
      <String>['Zid', 'Zidane'],
    );
  });

  testWidgets('a chip typed from a sticker finds the dog', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal('a-1', name: 'Bella'),
        _animal('a-2', name: 'Nala', microchipId: '984 221 330'),
      ],
    );

    await tester.enterText(_searchField, '984221');
    await tester.pump();

    expect(find.text('Nala'), findsOneWidget);
    expect(find.text('Bella'), findsNothing);
  });

  testWidgets(
    'nothing matches: the word comes back, and clearing the box brings the '
    'herd with it',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(tester, seed: <Animal>[_animal(_nalaId, name: 'Nala')]);

      await tester.enterText(_searchField, 'zzz');
      await tester.pump();

      expect(find.text('Nothing matches “zzz”'), findsOneWidget);
      expect(find.text('Nala'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('Nala'), findsOneWidget);
      expect(find.text('Nothing matches “zzz”'), findsNothing);
      // The corner button stays through a search: "nothing matches" next to
      // "Add animal" is the app's whole answer to a dog nobody registered yet.
      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );

  testWidgets('a search hides the agenda, which speaks for the whole herd', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal(_nalaId, name: 'Nala'),
        _animal('a-2', name: 'Bella'),
      ],
      seedVaccinations: <Vaccination>[_overdueDose()],
    );

    expect(find.text('Vaccinations to book'), findsOneWidget);

    await tester.enterText(_searchField, 'Nala');
    await tester.pump();

    // The card for the animal with the dose is still on screen, and so is the
    // word typed in the box; what is gone is the herd's to-do list, which would
    // otherwise read as a list about the one animal below it.
    expect(find.text('Vaccinations to book'), findsNothing);
    expect(find.text('Rabies was due 3 days ago'), findsNothing);
    expect(find.text('Nala'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Vaccinations to book'), findsOneWidget);
  });

  testWidgets('a space is not a search: the herd and its agenda both stay', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal(_nalaId, name: 'Nala'),
        _animal('a-2', name: 'Bella'),
      ],
      seedVaccinations: <Vaccination>[_overdueDose()],
    );

    expect(find.text('Vaccinations to book'), findsOneWidget);

    // A keyboard that puts a space after a word, or a dash typed before a
    // number: nothing normalises out of it, so the list is the whole herd — and
    // a herd nobody filtered has no business losing the block above it.
    await tester.enterText(_searchField, ' ');
    await tester.pump();

    expect(find.text('Vaccinations to book'), findsOneWidget);
    expect(find.text('Nala'), findsWidgets);
    expect(find.text('Bella'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('Arabic: the hamza a keyboard chose does not hide the dog', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[
        _animal('a-1', name: 'أسود'),
        _animal('a-2', name: 'بلة'),
      ],
    );

    await tester.enterText(_searchField, 'اسود');
    await tester.pump();

    expect(find.text('أسود'), findsOneWidget);
    expect(find.text('بلة'), findsNothing);
  });
}
