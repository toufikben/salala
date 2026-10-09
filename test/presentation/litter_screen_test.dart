import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/presentation/screens/litter_form_screen.dart';
import 'package:salala/presentation/widgets/animal_card.dart';

import '../helpers/pump_app.dart';

Animal _stock({required String name, required Sex sex}) => Animal(
  id: '',
  name: name,
  species: 'dog',
  breed: 'Border collie',
  sex: sex,
  status: AnimalStatus.active,
  isBreedingStock: true,
  createdAt: 0,
  updatedAt: 0,
);

/// A phone-sized surface: the litter form stacks five fields plus a dropdown,
/// and the default 800x600 test window leaves Save out of reach of a real tap.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openLittersTab(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Litters'));
  await settleRealIo(tester);
}

Future<void> _pickFrom(WidgetTester tester, Finder field, String option) async {
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  final item = find.text(option).last;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

/// The name and the dam and a puppy count, which every one of these tests needs
/// before it can talk about dates.
Future<void> _fillAroundDates(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FloatingActionButton, 'New litter'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Litter name'),
    'A litter',
  );
  await _pickFrom(tester, find.byType(DropdownButtonFormField<String>), 'Nala');
  await _pickFrom(tester, find.byType(DropdownButtonFormField<int>), '3');
}

void main() {
  // A tap that misses its widget must fail the test instead of only warning.
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('the litters tab starts empty and offers the guided state', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester);
    await _openLittersTab(tester);

    expect(find.text('No litters yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('a dam cannot be left out of a whelping', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _stock(name: 'Nala', sex: Sex.female),
        _stock(name: 'Atlas', sex: Sex.male),
      ],
    );
    await _openLittersTab(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New litter'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('A litter name is required'), findsOneWidget);
    expect(find.text('Choose the dam'), findsOneWidget);
    expect(find.byType(LitterFormScreen), findsOneWidget);
  });

  testWidgets('registering a whelping creates the litter and its puppies', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[
        _stock(name: 'Nala', sex: Sex.female),
        _stock(name: 'Atlas', sex: Sex.male),
      ],
    );
    await _openLittersTab(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New litter'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Litter name'),
      'A litter',
    );
    await _pickFrom(
      tester,
      find.byType(DropdownButtonFormField<String>),
      'Nala',
    );
    await _pickFrom(
      tester,
      find.byType(DropdownButtonFormField<String?>),
      'Atlas',
    );
    await _pickFrom(tester, find.byType(DropdownButtonFormField<int>), '3');

    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    // The litter and three animals are written through SQLite, so the fake
    // clock alone cannot finish the save.
    await settleRealIo(tester);

    // The route is gone and the list behind it shows the whelping: asserting on
    // the form being closed is what proves the tap landed.
    expect(find.byType(LitterFormScreen), findsNothing);
    expect(find.text('A litter'), findsOneWidget);
    expect(find.textContaining('Nala × Atlas'), findsOneWidget);
    expect(find.textContaining('3 puppies'), findsOneWidget);

    await tester.tap(find.text('A litter'));
    await tester.pumpAndSettle();

    expect(find.text('A litter 1'), findsOneWidget);
    expect(find.text('A litter 3'), findsOneWidget);
    expect(find.textContaining('2 puppies'), findsNothing);

    // A whelping detail is a pushed route with no nav bar of its own, so the
    // tab switch needs the way back first — the same order a hand follows.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Animals'));
    await settleRealIo(tester);

    // The puppies are animals now: that is the point of registering them here.
    expect(find.text('A litter 1'), findsOneWidget);
    expect(find.text('A litter 2'), findsOneWidget);
    expect(find.text('A litter 3'), findsOneWidget);
    expect(find.text('Breeding stock'), findsOneWidget);
  });

  testWidgets(
    'a whelping the database refuses is refused whole, and the form stays open',
    (tester) async {
      await pumpSalala(
        tester,
        seed: <Animal>[
          _stock(name: 'Nala', sex: Sex.female),
          _stock(name: 'Atlas', sex: Sex.male),
        ],
        beforeLaunch: refuseWritesTo('litters'),
      );
      await _openLittersTab(tester);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New litter'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Litter name'),
        'A litter',
      );
      await _pickFrom(
        tester,
        find.byType(DropdownButtonFormField<String>),
        'Nala',
      );
      await _pickFrom(tester, find.byType(DropdownButtonFormField<int>), '3');

      await tapSaveAndGetAnswer(tester);

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(LitterFormScreen),
        label: 'Litter name',
        text: 'A litter',
      );

      // And the sentence is the truth: the litter is written before its puppies
      // inside one transaction, so a refusal on that first row means three
      // animals named "A litter 1..3" were never created either. Back on the tab,
      // the whelping is not there — and the whelping tab only counts puppies, so
      // their names are looked for where an animal's name is actually drawn: the
      // herd list, which is where a transaction that had run would have left
      // three more cards.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await settleRealIo(tester);

      expect(find.text('A litter'), findsNothing);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Animals'));
      await settleRealIo(tester);
      // The two animals this test seeded, and the whole herd counted: the two
      // names alone would only prove the top of the list built, while a puppy
      // lands below them. The success test above is what makes this number mean
      // something — the same tab draws `A litter 1/2/3` as three cards when the
      // whelping is registered, so two cards here is the ledger read back.
      expect(find.text('Nala'), findsWidgets);
      expect(find.text('Atlas'), findsWidgets);
      expect(find.byType(AnimalCard), findsNWidgets(2));
      expect(find.text('A litter 1'), findsNothing);
      expect(find.text('A litter 2'), findsNothing);
      expect(find.text('A litter 3'), findsNothing);
    },
  );

  testWidgets(
    'a whelping dated before its mating is refused before anything is written',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_stock(name: 'Nala', sex: Sex.female)],
      );
      await _openLittersTab(tester);
      await _fillAroundDates(tester);
      await typeDateIntoPicker(
        tester,
        scope: LitterFormScreen,
        tile: 0,
        usDay: '06/01/2026',
      );
      await typeDateIntoPicker(
        tester,
        scope: LitterFormScreen,
        tile: 1,
        usDay: '01/01/2026',
      );

      await tapSaveAndGetAnswer(
        tester,
        waitingFor: whelpingBeforeMatingSentence,
      );

      expect(find.text(whelpingBeforeMatingSentence), findsOneWidget);
      expect(
        find.text(saveRefusalSentence),
        findsNothing,
        reason:
            'the screen has to stop on its own reading of the dates, not on a '
            'refusal from SQLite — the two sentences mean different things to a '
            'breeder, and only the first one tells them which field to change',
      );
      expect(find.byType(LitterFormScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Litter name'),
            )
            .controller!
            .text,
        'A litter',
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await settleRealIo(tester);
      expect(find.text('No litters yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Animals'));
      await settleRealIo(tester);
      // Nala and nobody else: the three puppies are made in the same save as the
      // litter, so a refusal that stopped early has to leave the herd one animal
      // wide. The control is the last test below — the same taps with the dates
      // the other way round put four cards here.
      expect(find.byType(AnimalCard), findsNWidgets(1));
    },
  );

  testWidgets(
    'a weaning dated before its whelping is refused, and named as that',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_stock(name: 'Nala', sex: Sex.female)],
      );
      await _openLittersTab(tester);
      await _fillAroundDates(tester);
      await typeDateIntoPicker(
        tester,
        scope: LitterFormScreen,
        tile: 0,
        usDay: '01/01/2026',
      );
      await typeDateIntoPicker(
        tester,
        scope: LitterFormScreen,
        tile: 1,
        usDay: '03/01/2026',
      );
      await typeDateIntoPicker(
        tester,
        scope: LitterFormScreen,
        tile: 2,
        usDay: '01/01/2026',
      );

      await tapSaveAndGetAnswer(
        tester,
        waitingFor: weaningBeforeWhelpingSentence,
      );

      // The sentence is the one about weaning: two rules that answer with the
      // same words would leave a breeder hunting for the wrong field, and the
      // mating above is a legal pair, so a generic refusal would also be a lie.
      expect(find.text(weaningBeforeWhelpingSentence), findsOneWidget);
      expect(find.text(whelpingBeforeMatingSentence), findsNothing);
      expect(find.byType(LitterFormScreen), findsOneWidget);
    },
  );

  testWidgets('the same whelping with its dates in order registers', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_stock(name: 'Nala', sex: Sex.female)],
    );
    await _openLittersTab(tester);
    await _fillAroundDates(tester);
    await typeDateIntoPicker(
      tester,
      scope: LitterFormScreen,
      tile: 0,
      usDay: '01/01/2026',
    );
    await typeDateIntoPicker(
      tester,
      scope: LitterFormScreen,
      tile: 1,
      usDay: '03/01/2026',
    );
    await typeDateIntoPicker(
      tester,
      scope: LitterFormScreen,
      tile: 2,
      usDay: '05/01/2026',
    );

    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await settleRealIo(tester);

    // Nothing is refused here, which is the point: the two tests above changed
    // one date each and nothing else, so a refusal they could not have avoided
    // would show up as this litter failing to land.
    expect(find.text(whelpingBeforeMatingSentence), findsNothing);
    expect(find.byType(LitterFormScreen), findsNothing);
    expect(find.text('A litter'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Animals'));
    await settleRealIo(tester);
    expect(find.byType(AnimalCard), findsNWidgets(4));
  });
}
