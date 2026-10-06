import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/triage.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/presentation/providers/triage_providers.dart';

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

void main() {
  testWidgets('the table the app loads is the table in the repository', (
    tester,
  ) async {
    // The engine is tested against the file on disk and the screen against
    // whatever the bundle hands it. This is the step that proves those are the
    // same file: an asset missing from `pubspec.yaml` would leave the card
    // showing an error on the phone while every other test stayed green.
    final source = await rootBundle.loadString(triageRulesAsset);
    expect(parseRules(source).length, TriageRuleId.values.length);
  });

  testWidgets('the provider that ships reads and parses that same table', (
    tester,
  ) async {
    // The body under test awaits `rootBundle` from inside a provider, and the
    // fake clock of `testWidgets` never lets such an await land: that is what
    // turned 21 screens into permanent progress bars in run 37435525579, and
    // why `pumpSalala` reads the file on the real clock and injects it. Here
    // `runAsync` puts the real clock back under this one call, so the read and
    // the parse the phone does stay covered — with no override, no stub, no
    // widget, and no database to hide behind.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    List<TriageRule>? rules;
    await tester.runAsync(
      () async => rules = await container.read(triageRulesProvider.future),
    );

    expect(rules, hasLength(TriageRuleId.values.length));
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
}
