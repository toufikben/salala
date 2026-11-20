import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/presentation/screens/animal_detail_screen.dart';
import 'package:companion/data/models/health_test.dart';
import 'package:companion/data/models/placement.dart';
import 'package:companion/data/models/vaccination.dart';
import 'package:companion/data/models/weight_entry.dart';
import 'package:companion/presentation/widgets/animal_timeline_card.dart';

import '../helpers/pump_app.dart';

int day(int year, int month, int dayOfMonth) =>
    DateTime(year, month, dayOfMonth).millisecondsSinceEpoch;

Animal _animal({String id = 'a1', String name = 'Nala'}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  breed: 'Border collie',
  sex: Sex.female,
  status: AnimalStatus.active,
  isBreedingStock: true,
  birthDate: day(2021, 4, 1),
  createdAt: 0,
  updatedAt: 0,
);

/// A phone-sized surface: a full animal page is taller than the default
/// 800x600 window, and the timeline sits under the identity card.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Brings a row of the ledger on stage: the page is a lazy list, so a section
/// below the fold has not been built yet.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.descendant(
      of: find.byType(AnimalDetailScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await settleRealIo(tester);
}

Future<void> _openAnimal(WidgetTester tester, String name) async {
  await tester.tap(find.text(name).first);
  await settleRealIo(tester);
}

void main() {
  testWidgets('the timeline is a reading of the records the page holds', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpApp(
      tester,
      seed: <Animal>[_animal()],
      seedVaccinations: <Vaccination>[
        Vaccination(
          id: 'v1',
          animalId: 'a1',
          vaccineName: 'Rabies',
          dateAdministered: day(2026, 5, 1),
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
      seedWeights: <WeightEntry>[
        WeightEntry(
          id: 'w1',
          animalId: 'a1',
          weightGrams: 21000,
          measuredAt: day(2026, 6, 1),
        ),
      ],
      seedHealthTests: <HealthTest>[
        HealthTest(
          id: 't1',
          animalId: 'a1',
          testType: 'Hips',
          result: 'Clear',
          testDate: day(2026, 4, 1),
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');

    final card = find.byType(AnimalTimelineCard);
    expect(card, findsOneWidget);

    // Every kind of record the page has written is on the card, and the dose
    // section further down still has its own row: the card is a second reading,
    // not a replacement, so both are on screen.
    for (final text in const <String>['Rabies', '21.00', 'Hips']) {
      final found = find.descendant(
        of: card,
        matching: find.textContaining(text),
      );
      expect(found, findsWidgets, reason: text);
    }
    expect(find.text('Rabies'), findsWidgets);
  });

  testWidgets('the newest record is the first line of the timeline', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpApp(
      tester,
      seed: <Animal>[_animal()],
      seedVaccinations: <Vaccination>[
        Vaccination(
          id: 'v1',
          animalId: 'a1',
          vaccineName: 'Rabies',
          dateAdministered: day(2026, 5, 1),
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
      seedWeights: <WeightEntry>[
        WeightEntry(
          id: 'w1',
          animalId: 'a1',
          weightGrams: 21000,
          measuredAt: day(2026, 6, 1),
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');

    final card = find.byType(AnimalTimelineCard);
    final rows = tester
        .widgetList<ListTile>(
          find.descendant(of: card, matching: find.byType(ListTile)),
        )
        .toList();
    expect(rows, isNotEmpty);

    // The weigh-in is June and the dose is May, so the weigh-in is above it.
    final weighIn = tester
        .getTopLeft(
          find.descendant(of: card, matching: find.textContaining('21.00')),
        )
        .dy;
    final doseAt = tester
        .getTopLeft(find.descendant(of: card, matching: find.text('Rabies')))
        .dy;
    expect(weighIn, lessThan(doseAt));
  });

  testWidgets('a handover with no day stays out of the timeline', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpApp(
      tester,
      seed: <Animal>[_animal()],
      seedPlacements: <Placement>[
        Placement(
          id: 'p1',
          animalId: 'a1',
          price: 2500,
          currency: 'MAD',
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');

    final card = find.byType(AnimalTimelineCard);
    // The card at the top of the page, where every dated row would be, does not
    // carry the amount: a row nobody dated cannot be put in order.
    expect(
      find.descendant(of: card, matching: find.textContaining('2500')),
      findsNothing,
    );

    // And the handover section further down still names it, which is the other
    // half of the promise — the row is not hidden, it is only out of the list.
    await _scrollTo(tester, find.textContaining('2500'));
    expect(find.textContaining('2500'), findsWidgets);
  });

  testWidgets('an animal with nothing dated says so', (tester) async {
    _usePhoneViewport(tester);
    await pumpApp(
      tester,
      seed: <Animal>[
        Animal(
          id: 'a1',
          name: 'Nala',
          species: 'dog',
          sex: Sex.female,
          status: AnimalStatus.active,
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');

    expect(find.text('Nothing dated yet.'), findsOneWidget);
  });

  testWidgets(
    'the card is capped, and the count of the rest is on the button',
    (tester) async {
      _usePhoneViewport(tester);
      // Seven doses: more than the card shows before it offers the rest.
      await pumpApp(
        tester,
        seed: <Animal>[_animal()],
        seedVaccinations: <Vaccination>[
          for (var index = 1; index <= 7; index++)
            Vaccination(
              id: 'v$index',
              animalId: 'a1',
              vaccineName: 'Dose $index',
              dateAdministered: day(2026, index, 1),
              createdAt: 0,
              updatedAt: 0,
            ),
        ],
      );
      await _openAnimal(tester, 'Nala');

      final card = find.byType(AnimalTimelineCard);
      final showAll = find.descendant(
        of: card,
        matching: find.textContaining('Show all'),
      );
      expect(showAll, findsOneWidget);
      // Seven records plus the birth date: the button names the whole list, not
      // the hidden part, so nothing is silently dropped.
      expect(tester.widget<Text>(showAll).data, 'Show all 8');

      // The button sits under six rows, so it is off the bottom of the phone: a
      // tap without bringing it on stage lands on whatever is there instead.
      await tester.ensureVisible(showAll);
      await tester.pumpAndSettle();
      await tester.tap(showAll);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: card, matching: find.textContaining('Show all')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Show fewer')),
        findsOneWidget,
      );
    },
  );

  testWidgets('a dose opens the screen that owns it', (tester) async {
    _usePhoneViewport(tester);
    await pumpApp(
      tester,
      seed: <Animal>[_animal()],
      seedVaccinations: <Vaccination>[
        Vaccination(
          id: 'v1',
          animalId: 'a1',
          vaccineName: 'Rabies',
          dateAdministered: day(2026, 5, 1),
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');

    await tester.tap(
      find.descendant(
        of: find.byType(AnimalTimelineCard),
        matching: find.text('Rabies'),
      ),
    );
    await settleRealIo(tester);

    // The edit form for that dose, which is where the row is corrected.
    expect(find.text('Edit vaccination'), findsOneWidget);
  });

  testWidgets('the timeline speaks Arabic', (tester) async {
    _usePhoneViewport(tester);
    await initializeDateFormatting();
    await pumpApp(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_animal()],
      seedWeights: <WeightEntry>[
        WeightEntry(
          id: 'w1',
          animalId: 'a1',
          weightGrams: 21000,
          measuredAt: day(2026, 6, 1),
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');

    expect(find.text('ما حدث'), findsOneWidget);
    final card = find.byType(AnimalTimelineCard);
    expect(
      find.descendant(of: card, matching: find.textContaining('وزن')),
      findsWidgets,
    );
  });
}
