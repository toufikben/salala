import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/symptom.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';
import 'package:salala/presentation/widgets/symptom_dialog.dart';
import 'package:salala/presentation/widgets/triage_card.dart';

import '../helpers/pump_app.dart';

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

Symptom _sighting({
  String label = 'Vomiting',
  SymptomSeverity severity = SymptomSeverity.severe,
  required int observedAt,
  bool ongoing = true,
}) => Symptom(
  id: '',
  animalId: _nalaId,
  label: label,
  severity: severity,
  observedAt: observedAt,
  ongoing: ongoing,
  createdAt: 0,
  updatedAt: 0,
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

/// The ledger is a lazy list, so a section below the fold does not exist yet;
/// the scrollable is taken from the detail screen so a route still held by the
/// router underneath cannot be scrolled by mistake.
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

/// What the triage card is actually showing, so a missing verdict says why.
///
/// A bare `expect(find.text('Act now'), findsOneWidget)` reads the same for
/// three different faults: the card is not built (this is a lazy page and the
/// card lives at its top), the card is still waiting on its query, or the card
/// answered with its retry button because the provider threw. Run
/// `38078494745` failed on all three of these assertions at once and the log
/// could not tell those apart, so the reason is part of the assertion.
String _cardReading(WidgetTester tester) {
  final card = find.descendant(
    of: find.byType(AnimalDetailScreen),
    matching: find.byType(TriageCard),
  );
  final words = card.evaluate().isEmpty
      ? 'no TriageCard is built on this page right now'
      : tester
            .widgetList<Text>(
              find.descendant(of: card, matching: find.byType(Text)),
            )
            .map((text) => text.data ?? '')
            .join(' | ');
  return tester.any(find.bySubtype<ProgressIndicator>())
      ? 'a widget is still loading; $words'
      : words;
}

Future<void> _save(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, 'Save');
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  // The row is written through SQLite and both the section and the card re-read
  // themselves afterwards, so one round of real waiting is not enough.
  await settleRealIo(tester);
  await settleRealIo(tester);
}

/// A sighting dated a fixed calendar day, built the same way the dialog builds
/// its own dates so the day the tile shows and the day asserted agree whatever
/// timezone the runner is in.
final int _seenOn = msFromDay(DateTime(2026, 3, 5));

/// The tile's subtitle: severity, ongoing or resolved, and the day it was seen.
String _tileSubtitle({
  required String severity,
  required String state,
  required String day,
}) => <String>[severity, state, day].join(' · ');

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'the Symptoms section lists label, severity and date from the row',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala()],
        seedSymptoms: <Symptom>[_sighting(observedAt: _seenOn)],
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Vomiting'));

      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.text('Vomiting'), findsOneWidget);
      expect(
        find.text(
          _tileSubtitle(
            severity: 'Severe',
            state: 'Still happening',
            day: formatDayFor('en', _seenOn),
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'an added symptom moves the card to act now without leaving the screen',
    (tester) async {
      // ROADMAP Stage 3a defect 1, in the record type the section added later:
      // the verdict has to follow a symptom typed on top of the ledger, not only
      // after a navigation. A severe sighting must jump the card to the act-now
      // label while the same screen stays open.
      _usePhoneViewport(tester);
      await pumpSalala(tester, seed: <Animal>[_nala()]);
      await _openNala(tester);

      expect(
        find.text('Nothing in this record calls for a next step'),
        findsOneWidget,
      );

      await _tap(tester, find.widgetWithText(TextButton, 'Add symptom'));
      expect(find.text('Log a symptom'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Symptom'),
        'Vomiting',
      );
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Severe'));
      await _save(tester);

      expect(find.text('Act now'), findsOneWidget);
      expect(
        find.text('Vomiting was recorded as severe and is still happening'),
        findsOneWidget,
      );
      await _scrollTo(tester, find.text('Vomiting'));
      expect(find.text('Vomiting'), findsOneWidget);
    },
  );

  testWidgets('marking a symptom resolved takes the finding off the card', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedSymptoms: <Symptom>[_sighting(observedAt: _seenOn)],
    );
    await _openNala(tester);
    // Read where the card lives before scrolling away from it: this page is a
    // lazy list, and an expect that only runs after the scroll cannot tell a
    // finding that never fired from a card the page stopped building.
    expect(
      find.text('Act now'),
      findsOneWidget,
      reason: 'before the scroll: ${_cardReading(tester)}',
    );
    await _scrollTo(tester, find.text('Vomiting'));

    expect(
      find.text('Act now'),
      findsOneWidget,
      reason: 'after the scroll: ${_cardReading(tester)}',
    );

    await _tap(tester, find.text('Vomiting'));
    expect(find.text('Edit symptom'), findsOneWidget);

    await _tap(tester, find.byType(Switch));
    await _save(tester);

    expect(find.text('Act now'), findsNothing);
    expect(
      find.text('Nothing in this record calls for a next step'),
      findsOneWidget,
      reason: _cardReading(tester),
    );
    // The fact survives as history; only the alarm stops. The row reads
    // "resolved" now, in the same joined subtitle it is shown in when open.
    await _scrollTo(tester, find.text('Vomiting'));
    expect(find.text('Vomiting'), findsOneWidget);
    expect(
      find.text(
        _tileSubtitle(
          severity: 'Severe',
          state: 'Resolved',
          day: formatDayFor('en', _seenOn),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting a symptom empties the section and clears the card', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_nala()],
      seedSymptoms: <Symptom>[_sighting(observedAt: _seenOn)],
    );
    await _openNala(tester);
    expect(
      find.text('Act now'),
      findsOneWidget,
      reason: 'before the scroll: ${_cardReading(tester)}',
    );
    await _scrollTo(tester, find.text('Vomiting'));

    expect(
      find.text('Act now'),
      findsOneWidget,
      reason: 'after the scroll: ${_cardReading(tester)}',
    );

    await _tap(tester, find.text('Vomiting'));
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRealIo(tester);
    await settleRealIo(tester);

    expect(find.text('Vomiting'), findsNothing);
    await _scrollTo(tester, find.text('Symptoms'));
    expect(find.text('Nothing recorded yet.'), findsWidgets);
    expect(find.text('Act now'), findsNothing);
    expect(
      find.text('Nothing in this record calls for a next step'),
      findsOneWidget,
      reason: _cardReading(tester),
    );
  });

  testWidgets('an empty label is refused and the dialog stays open', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_nala()]);
    await _openNala(tester);

    await _tap(tester, find.widgetWithText(TextButton, 'Add symptom'));
    await _save(tester);

    expect(find.text('Say what you saw'), findsOneWidget);
    expect(find.text('Log a symptom'), findsOneWidget);
    expect(find.text('Act now'), findsNothing);
  });

  testWidgets('the Arabic ledger renders the symptom date in Latin digits', (
    tester,
  ) async {
    // D21: an Arabic-Indic digit anywhere on screen is a defect, and the dialog
    // routes its date through formatDayFor, the same helper every other row uses.
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_nala()],
      seedSymptoms: <Symptom>[_sighting(label: 'استسقاء', observedAt: _seenOn)],
    );
    await _openNala(tester);

    final day = formatDayFor('ar', _seenOn);
    expect(RegExp(r'[0-9]').hasMatch(day), isTrue);
    expect(RegExp('[\u0660-\u0669]').hasMatch(day), isFalse);

    await _scrollTo(tester, find.text('استسقاء'));
    expect(
      find.text(
        _tileSubtitle(severity: 'شديد', state: 'ما زال مستمرًا', day: day),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'a symptom the database refuses keeps the dialog open and the button live',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala()],
        beforeLaunch: refuseWritesTo('symptoms'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Symptoms'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add symptom'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Symptom'),
        'Vomiting',
      );

      await tapSaveAndGetAnswer(tester, dialogTitle: 'Log a symptom');

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(SymptomDialog),
        label: 'Symptom',
        text: 'Vomiting',
        dialogTitle: 'Log a symptom',
      );
    },
  );

  testWidgets(
    'a symptom the database refuses to delete stays in the ledger and says so',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_nala()],
        seedSymptoms: <Symptom>[_sighting(observedAt: _seenOn)],
        beforeLaunch: refuseDeletesOf('symptoms'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Vomiting'));

      await _tap(tester, find.text('Vomiting'));
      await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settleRefusal(tester, waitingFor: deleteRefusalSentence);

      // The confirmation is gone, the edit dialog is still open over the row it
      // could not remove, and the triage card still alarms: an `ongoing` sighting
      // the ledger still holds is still a sign the breeder has to act on. A
      // Delete that answered with silence would have said the opposite.
      expect(find.text(deleteRefusalSentence), findsOneWidget);
      expect(find.byType(SymptomDialog), findsOneWidget);
      expect(
        find.text('Act now'),
        findsOneWidget,
        reason: _cardReading(tester),
      );
    },
  );

  testWidgets(
    'a sighting dated before the animal was born is refused, and the same '
    'dialog on a day after the birth does reach the ledger',
    (tester) async {
      _usePhoneViewport(tester);
      // Relative to the run's today on both sides: the sighting has to sit
      // inside the picker's fifteen-year window and still be before the birth,
      // and a fixed pair of dates stops satisfying both as the years pass.
      await pumpSalala(
        tester,
        seed: <Animal>[_nala().copyWith(birthDate: _daysAgo(400))],
        beforeLaunch: refuseWritesTo('symptoms'),
      );
      await _openNala(tester);
      await _scrollTo(tester, find.text('Symptoms'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add symptom'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Symptom'),
        'Vomiting',
      );
      await typeDateIntoPicker(
        tester,
        scope: AlertDialog,
        tile: 0,
        usDay: usDay(_daysAgo(500)),
      );

      await tapSaveAndGetAnswer(
        tester,
        dialogTitle: 'Log a symptom',
        waitingFor: beforeBirthSentence,
      );

      expect(find.text(beforeBirthSentence), findsOneWidget);
      expect(
        find.text(saveRefusalSentence),
        findsNothing,
        reason:
            'the insert trigger is what makes this absence mean anything: a '
            'sign dated five hundred days back would move the triage card, so '
            'the sentence has to be the form refusing, not SQLite — and the '
            'legal day below shows the trigger is live',
      );
      expect(find.byType(SymptomDialog), findsOneWidget);

      await typeDateIntoPicker(
        tester,
        scope: AlertDialog,
        tile: 0,
        usDay: usDay(_daysAgo(300)),
      );
      await tapSaveAndGetAnswer(tester, dialogTitle: 'Log a symptom');

      expectRefusedWrite(
        tester,
        stillOnScreen: find.byType(SymptomDialog),
        label: 'Symptom',
        text: 'Vomiting',
        dialogTitle: 'Log a symptom',
      );
    },
  );
}

int _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
