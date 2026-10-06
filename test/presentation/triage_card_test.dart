import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/triage.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';

import '../helpers/pump_app.dart';

const String _animalId = 'animal-triage';

const int _day = 86400000;

int _daysAgo(int days) =>
    DateTime.now().toUtc().millisecondsSinceEpoch - days * _day;

Animal _animal({int ageDays = 900}) => Animal(
  id: _animalId,
  name: 'Sira',
  species: 'dog',
  sex: Sex.male,
  status: AnimalStatus.active,
  birthDate: _daysAgo(ageDays),
  createdAt: 0,
  updatedAt: 0,
);

Vaccination _dose({int? dueInDays}) => Vaccination(
  id: '',
  animalId: _animalId,
  vaccineName: 'Rabies',
  dateAdministered: _daysAgo(100),
  nextDueDate: dueInDays == null ? null : _daysAgo(-dueInDays),
  createdAt: 0,
  updatedAt: 0,
);

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openLedger(WidgetTester tester) async {
  await tester.tap(find.text('Sira'));
  await settleRealIo(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
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

WeightEntry _weigh(int grams, int daysAgo) => WeightEntry(
  id: '',
  animalId: _animalId,
  weightGrams: grams,
  measuredAt: _daysAgo(daysAgo),
);

void main() {
  testWidgets('the table the app loads is the table in the repository', (
    tester,
  ) async {
    // The engine is tested against the file on disk and the screen against
    // whatever the bundle hands it. This is the step that proves those are the
    // same file: an asset missing from `pubspec.yaml` would leave the card
    // showing an error on the phone while every other test stayed green.
    //
    // It is also the only place this repo can put an `await rootBundle` and have
    // it land. From a provider body it never completes, and neither does it from
    // inside `tester.runAsync` — see the note in `test/helpers/pump_app.dart`,
    // which is where the shipped table now comes from and why the provider's own
    // read path is verified on a phone rather than here.
    final source = await rootBundle.loadString(triageRulesAsset);
    expect(parseRules(source).length, TriageRuleId.values.length);
  });

  testWidgets('a young animal with no dose is shown as act now', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_animal(ageDays: 90)]);
    await _openLedger(tester);

    expect(find.text('Act now'), findsOneWidget);
    expect(
      find.text('No vaccination recorded, at 90 days old'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Salala reads only what you typed here. '
        'This is not a veterinary diagnosis.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a settled adult record says there is nothing to do', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal()],
      seedVaccinations: <Vaccination>[_dose(dueInDays: 100)],
    );
    await _openLedger(tester);

    expect(
      find.text('Nothing in this record calls for a next step'),
      findsOneWidget,
    );
    expect(find.text('Act now'), findsNothing);
  });

  testWidgets('an overdue dose reaches the card in Arabic', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_animal()],
      seedVaccinations: <Vaccination>[_dose(dueInDays: -20)],
    );
    await _openLedger(tester);

    expect(find.text('زيارة بيطرية روتينية'), findsOneWidget);
    // D21: the count of days is Latin even in the Arabic sentence.
    expect(find.text('Rabies كان مستحقًا منذ 20 يومًا'), findsOneWidget);
  });

  testWidgets('the card moves when a record is saved on top of it', (
    tester,
  ) async {
    // This is the phone's bug, written down. On the Realme the ledger said
    // "Nothing in this record calls for a next step" while a Rabies dose due the
    // next morning sat in the section below it, and only leaving the screen and
    // coming back moved the card: the verdict was a snapshot of the moment the
    // page opened, because nothing in the write path invalidated it. The whole
    // point of deriving it from the record lists instead is that this test has
    // to pass without a navigation in it.
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal()],
      seedWeights: <WeightEntry>[_weigh(1000, 25)],
    );
    await _openLedger(tester);

    expect(
      find.text('Nothing in this record calls for a next step'),
      findsOneWidget,
    );

    await _tap(tester, find.widgetWithText(TextButton, 'Add weight'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Weight (kg)'),
      '0.8',
    );
    await _save(tester);

    expect(find.text('Keep watching'), findsOneWidget);
    expect(
      find.text('Weight has fallen 20% since the last weigh-in'),
      findsOneWidget,
    );
  });
}
