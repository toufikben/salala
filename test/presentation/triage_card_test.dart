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

  testWidgets('the table reaches a widget through its own provider', (
    tester,
  ) async {
    // What the two red runs left unproven: the bundle is reachable from a test
    // body, but the screen reads the table through a provider, and that is a
    // different await chain running inside the fake-async zone. Standing alone,
    // with no database and no ledger page in it, this is the test that says
    // which layer failed — a stuck progress bar here is the bundle, and
    // anywhere else it is the wiring around it.
    List<TriageRule>? seen;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ref
                .watch(triageRulesProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stack) => const Text('the table did not load'),
                  data: (rules) {
                    seen = rules;
                    return Text('ready ${rules.length}');
                  },
                ),
          ),
        ),
      ),
    );
    await settleRealIo(tester);

    expect(seen?.length, TriageRuleId.values.length);
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
