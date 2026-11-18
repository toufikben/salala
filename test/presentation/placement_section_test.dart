import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';
import 'package:salala/presentation/widgets/placement_dialog.dart';

import '../helpers/fake_contract_files.dart';
import '../helpers/pump_app.dart';
import '../helpers/section_finder.dart';

/// Fixed ids, for the same reason the symptom section's are: a placement rows
/// under an animal by foreign key and names a buyer by one, so the test has to
/// know both ids to seed a handover at all.
const String _nalaId = 'animal-nala';
const String _atlasId = 'animal-atlas';
const String _aichaId = 'buyer-aicha';

Animal _animal(String id, String name) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  createdAt: 0,
  updatedAt: 0,
);

Buyer _aicha({String name = 'Aicha'}) => Buyer(
  id: _aichaId,
  name: name,
  phone: '0611111111',
  createdAt: 0,
  updatedAt: 0,
);

/// A handover dated a fixed calendar day, built the way the dialog builds its
/// own dates, so the day the tile prints and the day asserted agree whatever
/// timezone the runner is in.
final int _placedOn = msFromDay(DateTime(2026, 4, 18));

Placement _handover({
  required String id,
  required int placed,
  String animalId = _nalaId,
  String? buyerId = _aichaId,
  double? price,
  String? currency,
  String? guarantee,
  String? contract,
}) => Placement(
  id: id,
  animalId: animalId,
  buyerId: buyerId,
  placedDate: placed,
  price: price,
  currency: currency,
  guaranteeTerms: guarantee,
  contractFilePath: contract,
  createdAt: 0,
  updatedAt: 0,
);

/// The row's subtitle, in the order the tile joins it: day, amount, guarantee.
String _rowDetails({
  required String localeTag,
  required int placed,
  String? amount,
  String? guarantee,
}) =>
    <String>[formatDayFor(localeTag, placed), ?amount, ?guarantee].join(' · ');

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openAnimal(WidgetTester tester, String name) async {
  await tester.tap(sectionText(name));
  await settleRealIo(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // A row below the fold does not exist yet: the ledger is a lazy list,
  // and the timeline card above the sections moved everything down, so the
  // scroll comes before the `ensureVisible` that used to be enough alone.
  if (finder.evaluate().isEmpty) {
    await _scrollTo(tester, finder);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await _letFarewellExpire(tester);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Waits out a farewell message sitting over the bottom of the screen.
///
/// Saving a handover now says one sentence there, and it is drawn over the
/// ledger — which is exactly where the next tap after a save wants to land.
/// Four seconds of a message nobody in this test is asking about is worth
/// waiting for, and much better than a tap that quietly hits the snackbar.
Future<void> _letFarewellExpire(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isEmpty) return;
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// The ledger is a lazy list, so the Placements section — the last one — does
/// not exist until it is scrolled to. The scrollable is taken from the detail
/// screen, so a list still held by the router underneath cannot be scrolled by
/// mistake.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.descendant(
      of: find.byType(AnimalDetailScreen),
      matching: find.byType(Scrollable),
    ),
  );
  // `settleRealIo`, not `pumpAndSettle`: scrolling to a section can land on one
  // that is still reading the ledger, and its indeterminate bar never settles —
  // the helper waits for the bar instead of timing out on it.
  await settleRealIo(tester);
}

/// Taps the Save button of one open dialog.
///
/// Scoped by title because the placement form and the contact form are stacked
/// on each other for part of this flow, and both end in a FilledButton that
/// reads "Save": an unscoped finder would tap whichever one the widget tree
/// happens to visit first, and the test would save the wrong record.
///
/// The wait is on the dialog closing, not on a frame count: the row is written
/// through SQLite on another isolate, and a busy machine can still be inside the
/// write while the fixed rounds run out — which left the barrier up and made the
/// next tap land on it instead of on the button behind it.
Future<void> _saveIn(WidgetTester tester, String dialogTitle) async {
  final save = find.descendant(
    of: find.widgetWithText(AlertDialog, dialogTitle),
    matching: find.widgetWithText(FilledButton, 'Save'),
  );
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await settleUntil(
    tester,
    () => find.widgetWithText(AlertDialog, dialogTitle).evaluate().isEmpty,
  );
  // The row is written through SQLite, and both the contact list and this
  // animal's placements re-read themselves afterwards.
  await settleRealIo(tester);
}

/// Opens the contact form of the buyer a handover already names.
///
/// Reached from the handover form rather than from a contacts screen: the book
/// has no such screen, and a contact the breeder can only see through a
/// handover is still a person whose phone number is in the app.
Future<void> _editBuyer(WidgetTester tester) async {
  await _tap(tester, find.byTooltip('Edit buyer'));
  expect(sectionText('Edit buyer'), findsOneWidget);
}

/// Taps the contact form's Delete action and stops on the confirmation, so the
/// caller chooses the answer and waits for whatever the database does next.
Future<void> _askToDeleteBuyer(WidgetTester tester) async {
  await _tap(
    tester,
    find.descendant(
      of: find.widgetWithText(AlertDialog, 'Edit buyer'),
      matching: find.widgetWithText(TextButton, 'Delete'),
    ),
  );
  expect(sectionText('Delete this record?'), findsOneWidget);
}

Future<void> _answerDeletePrompt(WidgetTester tester, String action) async {
  await tester.tap(
    find.descendant(
      of: find.widgetWithText(AlertDialog, 'Delete this record?'),
      matching: find.widgetWithText(
        action == 'Delete' ? FilledButton : TextButton,
        action,
      ),
    ),
  );
}

/// Closes a dialog with its Cancel button, scoped by title because the handover
/// form and the contact form are stacked on each other and both offer one.
Future<void> _cancelDialog(WidgetTester tester, String dialogTitle) async {
  await _tap(
    tester,
    find.descendant(
      of: find.widgetWithText(AlertDialog, dialogTitle),
      matching: find.widgetWithText(TextButton, 'Cancel'),
    ),
  );
}

/// Names a buyer in the contact form and saves it, leaving the placement form
/// with that contact selected.
Future<void> _createBuyer(WidgetTester tester, String name) async {
  await _tap(tester, find.byTooltip('New buyer'));
  expect(sectionText('Add a buyer'), findsOneWidget);
  await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
  await _saveIn(tester, 'Add a buyer');
}

/// Opens the handover form, fills the money, and saves.
Future<void> _priceAndSave(
  WidgetTester tester,
  String dialogTitle, {
  required String price,
  String? currency,
  String? guarantee,
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Price'), price);
  if (currency != null) {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Currency'),
      currency,
    );
  }
  if (guarantee != null) {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Guarantee terms'),
      guarantee,
    );
  }
  await _saveIn(tester, dialogTitle);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('the Placements section says nothing has been handed over', (
    tester,
  ) async {
    // The case the paid export was always shipping empty: an animal with a full
    // health record and no placement prints no buyer block at all.
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Placements'));

    expect(sectionText('Placements'), findsOneWidget);
    expect(sectionText('Add placement'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'Placements'),
        matching: sectionText('Nothing recorded yet.'),
      ),
      findsOneWidget,
    );
    // The absence is the row's own wording, so an empty section cannot be
    // confused for a placement whose buyer was never named.
    expect(sectionText('Buyer not recorded'), findsNothing);
  });

  testWidgets(
    'a placement written through the form appears and survives reopening',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Placements'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
      expect(sectionText('Log a placement'), findsOneWidget);

      await _createBuyer(tester, 'Aicha');
      // The contact form closed and the handover form is holding the buyer it
      // just wrote — the id the dao assigned, not one typed by hand.
      expect(sectionText('Aicha'), findsOneWidget);

      await _priceAndSave(
        tester,
        'Log a placement',
        price: '2500',
        currency: 'mad',
        guarantee: 'Health guarantee for 15 days',
      );

      expect(sectionText('Log a placement'), findsNothing);
      // The handover closed with one sentence about the animal rather than about
      // the record: what a breeder needs to hear after sending a dog away is
      // that the ledger did not go with her.
      expect(
        sectionText('Nala has gone to a new home. The record stays with you.'),
        findsOneWidget,
      );
      await _letFarewellExpire(tester);
      await _scrollTo(tester, sectionText('Aicha'));
      expect(sectionText('Aicha'), findsOneWidget);
      // The amount is printed ungrouped with the code upper-cased by the form,
      // and the day defaults to the one it was written on.
      expect(sectionTextContaining('2500 MAD'), findsOneWidget);

      // Back to the herd and into the same ledger again: the row has to come
      // off SQLite, not out of a provider the screen happened to keep.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settleRealIo(tester);
      expect(find.byType(AnimalDetailScreen), findsNothing);

      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Aicha'));
      expect(sectionText('Aicha'), findsOneWidget);
      expect(
        sectionTextContaining('Health guarantee for 15 days'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a buyer created for one animal is offered for the next one', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala'), _animal(_atlasId, 'Atlas')],
    );
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await _createBuyer(tester, 'Aicha');
    await _saveIn(tester, 'Log a placement');
    await _scrollTo(tester, sectionText('Aicha'));
    expect(sectionText('Aicha'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await settleRealIo(tester);
    await _openAnimal(tester, 'Atlas');
    await _scrollTo(tester, sectionText('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await _tap(tester, find.byType(DropdownButtonFormField<String?>));
    // A contact list, not a per-animal field: the same family takes the second
    // litter, and the name typed for Nala is a choice here without being
    // typed again.
    expect(sectionText('Aicha'), findsOneWidget);
    await _tap(tester, sectionText('Aicha'));
    await _saveIn(tester, 'Log a placement');

    await _scrollTo(tester, sectionText('Aicha'));
    // On Atlas's ledger, with the form closed: the contact came back out of
    // SQLite after the first screen was thrown away, not out of a provider
    // this route kept.
    expect(find.byType(AlertDialog), findsNothing);
    expect(sectionText('Aicha'), findsOneWidget);
  });

  testWidgets('tapping a row edits it and the row changes', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_aicha()],
      seedPlacements: <Placement>[
        _handover(
          id: 'placement-1',
          placed: _placedOn,
          price: 2500,
          currency: 'MAD',
          guarantee: 'Health guarantee for 15 days',
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Aicha'));

    expect(
      sectionText(
        _rowDetails(
          localeTag: 'en',
          placed: _placedOn,
          amount: '2500 MAD',
          guarantee: 'Health guarantee for 15 days',
        ),
      ),
      findsOneWidget,
    );

    await _tap(tester, sectionText('Aicha'));
    expect(sectionText('Edit placement'), findsOneWidget);
    // The stored values are in the fields already, so correcting one row does
    // not mean retyping the rest of it.
    expect(sectionText('Health guarantee for 15 days'), findsWidgets);

    await _priceAndSave(tester, 'Edit placement', price: '1800');

    await _scrollTo(tester, sectionTextContaining('1800 MAD'));
    expect(
      sectionText(
        _rowDetails(
          localeTag: 'en',
          placed: _placedOn,
          amount: '1800 MAD',
          guarantee: 'Health guarantee for 15 days',
        ),
      ),
      findsOneWidget,
    );
    expect(sectionTextContaining('2500 MAD'), findsNothing);
  });

  testWidgets('deleting one placement leaves the other handover', (
    tester,
  ) async {
    // Two rows on purpose: an animal bought back and re-homed is a real ledger
    // state, and the delete that takes the whole history with it is the failure
    // this checks for.
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_aicha()],
      seedPlacements: <Placement>[
        _handover(id: 'placement-old', placed: _placedOn),
        _handover(
          id: 'placement-new',
          placed: msFromDay(DateTime(2026, 9, 2)),
          buyerId: null,
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');
    // The undated-in-advance row is the newest one, so it is the row this scroll
    // targets: the ledger is lazy and the second tile does not exist yet.
    await _scrollTo(tester, sectionText('Buyer not recorded'));

    expect(sectionText('Buyer not recorded'), findsOneWidget);

    await _tap(tester, sectionText('Buyer not recorded'));
    expect(sectionText('Edit placement'), findsOneWidget);
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(sectionText('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // A placement delete pops the dialog, rewrites the animal's status, and
    // re-reads two lists before the row leaves the screen. Waiting for the
    // dialog to close is waiting for the whole chain, not for a fixed count of
    // frames — the fixed count is what made this pass alone and fail in a suite.
    await settleUntil(
      tester,
      () => find.byType(AlertDialog).evaluate().isEmpty,
    );
    await settleRealIo(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(sectionText('Buyer not recorded'), findsNothing);
    await _scrollTo(tester, sectionText('Aicha'));
    expect(sectionText('Aicha'), findsOneWidget);
  });

  testWidgets('the Arabic ledger prints the placement price in Latin digits', (
    tester,
  ) async {
    // D21, for the one row a buyer reads off the document: an amount typed 2500
    // has to arrive as 2500 in Arabic too, next to Arabic words.
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_animal(_nalaId, 'نلة')],
      seedBuyers: <Buyer>[_aicha(name: 'عائشة')],
      seedPlacements: <Placement>[
        _handover(
          id: 'placement-1',
          placed: _placedOn,
          price: 2500,
          currency: 'MAD',
        ),
      ],
    );
    await _openAnimal(tester, 'نلة');
    await _scrollTo(tester, sectionText('عائشة'));

    expect(sectionText('التسليم'), findsOneWidget);
    final details = sectionText(
      _rowDetails(localeTag: 'ar', placed: _placedOn, amount: '2500 MAD'),
    );
    expect(details, findsOneWidget);

    final rendered = tester.widget<Text>(details).data!;
    // Only the digits are checked: the month name is supposed to stay Arabic.
    expect(RegExp('[\u0660-\u0669]').hasMatch(rendered), isFalse);
    expect(RegExp('[0-9]').hasMatch(rendered), isTrue);
    expect(rendered.contains('2500 MAD'), isTrue);
  });

  testWidgets(
    'a handover the database refuses keeps the dialog open and the button live',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        beforeLaunch: refuseWritesTo('placements'),
      );
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Placements'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '2500',
      );

      await tapSaveAndGetAnswer(tester, dialogTitle: 'Log a placement');

      expectRefusedWrite(
        tester,
        stillOnScreen: find.widgetWithText(AlertDialog, 'Log a placement'),
        label: 'Price',
        text: '2500',
        dialogTitle: 'Log a placement',
      );
    },
  );

  testWidgets(
    'a contact the database refuses leaves both dialogs holding their words',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        beforeLaunch: refuseWritesTo('buyers'),
      );
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Placements'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
      await _tap(tester, find.byTooltip('New buyer'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Aicha',
      );

      await tapSaveAndGetAnswer(tester, dialogTitle: 'Add a buyer');

      expectRefusedWrite(
        tester,
        stillOnScreen: find.widgetWithText(AlertDialog, 'Add a buyer'),
        label: 'Name',
        text: 'Aicha',
        dialogTitle: 'Add a buyer',
      );
      // And the handover it was opened from is still there underneath, with no
      // buyer selected: a contact that did not reach the ledger cannot be the
      // name printed on a placement document.
      expect(
        find.widgetWithText(AlertDialog, 'Log a placement'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a handover dated before the animal was born is refused, and the same '
      'dialog on a day after the birth does reach the ledger', (tester) async {
    _usePhoneViewport(tester);
    // Both dates come off the run's own today: a handover can be booked a year
    // ahead and reached fifteen years back, so the only pair that stays legal
    // on a runner in another year is a relative one.
    await pumpSalala(
      tester,
      seed: <Animal>[
        _animal(_nalaId, 'Nala').copyWith(birthDate: _daysAgo(400)),
      ],
      seedBuyers: <Buyer>[_aicha()],
      beforeLaunch: refuseWritesTo('placements'),
    );
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '2500');
    await typeDateIntoPicker(
      tester,
      scope: AlertDialog,
      tile: 0,
      usDay: usDay(_daysAgo(500)),
    );

    await tapSaveAndGetAnswer(
      tester,
      dialogTitle: 'Log a placement',
      waitingFor: beforeBirthSentence,
    );

    expect(sectionText(beforeBirthSentence), findsOneWidget);
    expect(
      sectionText(saveRefusalSentence),
      findsNothing,
      reason:
          'the trigger is what turns this absence into evidence: a handover '
          'that did reach SQLite with these dates would have been refused by '
          'the database and answered with that other sentence, and the legal '
          'day below shows the trigger does bite',
    );
    expect(find.byType(PlacementDialog), findsOneWidget);
    await typeDateIntoPicker(
      tester,
      scope: AlertDialog,
      tile: 0,
      usDay: usDay(_daysAgo(300)),
    );
    await tapSaveAndGetAnswer(tester, dialogTitle: 'Log a placement');

    expectRefusedWrite(
      tester,
      stillOnScreen: find.byType(PlacementDialog),
      label: 'Price',
      text: '2500',
      dialogTitle: 'Log a placement',
    );
  });

  testWidgets('deleting a contact keeps the handover and blanks its buyer', (
    tester,
  ) async {
    // The two things this path must not confuse: the animal's history belongs to
    // the animal, the phone number belongs to the person. The handover survives
    // the delete with no buyer named — `placements.buyer_id ... ON DELETE SET
    // NULL`, which the transfer pack then prints as its own sentence.
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_aicha()],
      seedPlacements: <Placement>[
        _handover(
          id: 'placement-1',
          placed: _placedOn,
          price: 2500,
          currency: 'MAD',
        ),
      ],
    );
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Aicha'));

    await _tap(tester, sectionText('Aicha'));
    expect(sectionText('Edit placement'), findsOneWidget);
    await _editBuyer(tester);
    // The form opened on the row the ledger holds, so the name in the box is the
    // name being deleted — not whatever was typed last.
    expect(
      tester
          .widget<TextFormField>(
            find.descendant(
              of: find.widgetWithText(AlertDialog, 'Edit buyer'),
              matching: find.widgetWithText(TextFormField, 'Name'),
            ),
          )
          .controller!
          .text,
      'Aicha',
    );

    await _askToDeleteBuyer(tester);
    await _answerDeletePrompt(tester, 'Delete');
    // The delete runs on SQLite and the contact form pops behind it, so this
    // waits for the dialog to be gone instead of for two rounds of frames.
    await settleUntil(
      tester,
      () => find.widgetWithText(AlertDialog, 'Edit buyer').evaluate().isEmpty,
    );

    // The contact form closed on its own; the handover form it was opened from is
    // still here, so removing a name does not throw away a record mid-correction.
    expect(find.widgetWithText(AlertDialog, 'Edit buyer'), findsNothing);
    expect(find.widgetWithText(AlertDialog, 'Edit placement'), findsOneWidget);
    await _cancelDialog(tester, 'Edit placement');

    await _scrollTo(tester, sectionText('Buyer not recorded'));
    expect(sectionText('Buyer not recorded'), findsOneWidget);
    expect(sectionText('Aicha'), findsNothing);

    // Off the ledger and back into it: the row printed below is SQLite's, so the
    // handover did not go with the contact and neither did its amount.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settleRealIo(tester);
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Buyer not recorded'));
    expect(sectionText('Buyer not recorded'), findsOneWidget);
    expect(sectionTextContaining('2500 MAD'), findsOneWidget);
  });

  testWidgets(
    'a contact created and then removed in the same handover form still saves',
    (tester) async {
      // The form keeps the contact it wrote itself, next to its id, because the list
      // reload takes real time on the database isolate. That snapshot is the one
      // thing here that can still name a person the ledger no longer has — and a
      // handover that cannot be saved, answered with "try again" over a name that is
      // already gone, is a dead end nobody could dig themselves out of.
      _usePhoneViewport(tester);
      await pumpSalala(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Placements'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
      await _createBuyer(tester, 'Aicha');
      // The pencil only appears on a contact the loaded list answers to, so this is
      // also the moment the form stops holding its own snapshot as the only copy.
      expect(find.byTooltip('Edit buyer'), findsOneWidget);
      await _editBuyer(tester);
      await _askToDeleteBuyer(tester);
      await _answerDeletePrompt(tester, 'Delete');
      // The contact form closes once the row is gone and the handover form takes
      // its name back out; waited for by that, not by a count of frames.
      await settleUntil(
        tester,
        () => find.widgetWithText(AlertDialog, 'Edit buyer').evaluate().isEmpty,
      );

      expect(
        find.descendant(
          of: find.widgetWithText(AlertDialog, 'Log a placement'),
          matching: sectionText('Buyer not recorded'),
        ),
        findsOneWidget,
      );

      await _priceAndSave(
        tester,
        'Log a placement',
        price: '2500',
        currency: 'mad',
      );

      expect(find.widgetWithText(AlertDialog, 'Log a placement'), findsNothing);
      expect(
        sectionText(saveRefusalSentence),
        findsNothing,
        reason: 'the handover has no buyer left to name, so SQLite has nothing to refuse',
      );
      await _scrollTo(tester, sectionTextContaining('2500 MAD'));
      expect(sectionText('Buyer not recorded'), findsOneWidget);
      expect(sectionText('Aicha'), findsNothing);
    },
  );

  testWidgets(
    'a contact the database refuses to delete is still offered and still named',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(
        tester,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        seedBuyers: <Buyer>[_aicha()],
        seedPlacements: <Placement>[
          _handover(id: 'placement-1', placed: _placedOn),
        ],
        beforeLaunch: refuseDeletesOf('buyers'),
      );
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Aicha'));

      await _tap(tester, sectionText('Aicha'));
      await _editBuyer(tester);
      await _askToDeleteBuyer(tester);
      await _answerDeletePrompt(tester, 'Delete');
      await settleRefusal(tester, waitingFor: deleteRefusalSentence);

      expect(sectionText(deleteRefusalSentence), findsOneWidget);
      final editBuyer = find.widgetWithText(AlertDialog, 'Edit buyer');
      // A person SQLite kept stays the form's to show: it did not close on a delete
      // that never happened, the name is still in the box, and the button answers a
      // second tap instead of freezing disabled.
      expect(editBuyer, findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: editBuyer,
                matching: find.widgetWithText(TextFormField, 'Name'),
              ),
            )
            .controller!
            .text,
        'Aicha',
      );
      expect(
        tester
            .widget<TextButton>(
              find.descendant(
                of: editBuyer,
                matching: find.widgetWithText(TextButton, 'Delete'),
              ),
            )
            .onPressed,
        isNotNull,
      );

      // The sentence has to be gone before these buttons are tapped again: this
      // runner treats a hit-test warning as fatal, and a snackbar still on the
      // screen is one more thing in the way.
      await tester.pump(const Duration(seconds: 5));
      await _cancelDialog(tester, 'Edit buyer');
      await _cancelDialog(tester, 'Edit placement');
      expect(sectionText('Aicha'), findsOneWidget);
      expect(sectionText('Buyer not recorded'), findsNothing);
    },
  );

  testWidgets('cancelling the confirmation deletes nobody', (tester) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_aicha()],
      seedPlacements: <Placement>[
        _handover(id: 'placement-1', placed: _placedOn),
      ],
    );
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Aicha'));

    await _tap(tester, sectionText('Aicha'));
    await _editBuyer(tester);
    await _askToDeleteBuyer(tester);
    await _answerDeletePrompt(tester, 'Cancel');
    await tester.pumpAndSettle();

    // The question was asked once and the answer was no: the contact form is back
    // where it was, and the ledger still has the buyer behind it.
    expect(sectionText('Delete this record?'), findsNothing);
    expect(find.widgetWithText(AlertDialog, 'Edit buyer'), findsOneWidget);
    await _cancelDialog(tester, 'Edit buyer');
    await _cancelDialog(tester, 'Edit placement');
    expect(sectionText('Aicha'), findsOneWidget);
    expect(sectionText('Buyer not recorded'), findsNothing);
  });

  testWidgets('a contact being created offers no delete', (tester) async {
    // Nobody has been written yet, so there is nothing to remove — and a Delete
    // button on a new contact would ask the database to delete an id that does
    // not exist.
    _usePhoneViewport(tester);
    await pumpSalala(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
    await _openAnimal(tester, 'Nala');
    await _scrollTo(tester, sectionText('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await _tap(tester, find.byTooltip('New buyer'));
    expect(sectionText('Add a buyer'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(AlertDialog, 'Add a buyer'),
        matching: find.widgetWithText(TextButton, 'Delete'),
      ),
      findsNothing,
    );
  });

  group('the contract on a handover', () {
    /// The form's attach row, in the state it starts in.
    Finder attachRow() => find.widgetWithText(ListTile, 'Attach a contract');

    testWidgets(
      'a chosen document is written, named on the row, and openable',
      (tester) async {
        _usePhoneViewport(tester);
        final contracts = FakeContractFiles()
          ..nextPicked = FakeContractFiles.contract('signed.pdf', bytes: 64);
        await pumpSalala(
          tester,
          seed: <Animal>[_animal(_nalaId, 'Nala')],
          contractFiles: contracts,
        );
        await _openAnimal(tester, 'Nala');
        await _scrollTo(tester, sectionText('Placements'));

        await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
        await _tap(tester, attachRow());
        // Nothing is on the disk yet: the bytes are held in the form until Save, so
        // a breeder who backs out leaves no file behind.
        expect(contracts.stored, isEmpty);
        expect(sectionText('Contract attached'), findsOneWidget);
        expect(sectionText('signed.pdf'), findsOneWidget);

        await _saveIn(tester, 'Log a placement');
        expect(contracts.stored, <String>['$_nalaId/signed.pdf-64']);

        await _letFarewellExpire(tester);
        await _scrollTo(tester, sectionText('Buyer not recorded'));
        // The row grew its own control: this handover has a document behind it.
        expect(find.byTooltip('Open the contract'), findsOneWidget);

        await _tap(tester, find.byTooltip('Open the contract'));
        expect(contracts.opened, <String>['$_nalaId/signed.pdf-64']);
      },
    );

    testWidgets(
      'a document that is not on this phone says so instead of opening',
      (tester) async {
        // The state a restored ledger is in: the row travelled, the file did not.
        _usePhoneViewport(tester);
        final contracts = FakeContractFiles();
        await pumpSalala(
          tester,
          seed: <Animal>[_animal(_nalaId, 'Nala')],
          seedPlacements: <Placement>[
            _handover(
              id: 'p-1',
              placed: _placedOn,
              buyerId: null,
              contract: 'gone.pdf',
            ),
          ],
          contractFiles: contracts,
        );
        await _openAnimal(tester, 'Nala');
        await _scrollTo(tester, find.byTooltip('Open the contract'));

        await _tap(tester, find.byTooltip('Open the contract'));

        expect(
          sectionText('That document is not on this phone'),
          findsOneWidget,
        );
        expect(contracts.opened, <String>['$_nalaId/gone.pdf']);
      },
    );

    testWidgets('removing the contract deletes the file the row used to name', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final contracts = FakeContractFiles(
        bytes: <String, List<int>>{
          '$_nalaId/old.pdf-8': <int>[1, 2, 3],
        },
      );
      await pumpSalala(
        tester,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        seedPlacements: <Placement>[
          _handover(
            id: 'p-1',
            placed: _placedOn,
            buyerId: null,
            contract: 'old.pdf-8',
          ),
        ],
        contractFiles: contracts,
      );
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Buyer not recorded'));

      await _tap(tester, sectionText('Buyer not recorded'));
      expect(sectionText('Contract attached'), findsOneWidget);

      await _tap(tester, find.byTooltip('Remove the contract'));
      expect(sectionText('Attach a contract'), findsOneWidget);
      await _saveIn(tester, 'Edit placement');

      // Written after the row landed, never before: a save that failed would
      // otherwise have destroyed a contract the row still names.
      expect(contracts.deleted, <String>['$_nalaId/old.pdf-8']);
      expect(find.byTooltip('Open the contract'), findsNothing);
    });

    testWidgets('backing out of the form removes nothing', (tester) async {
      _usePhoneViewport(tester);
      final contracts = FakeContractFiles(
        bytes: <String, List<int>>{
          '$_nalaId/old.pdf-8': <int>[1, 2, 3],
        },
      );
      await pumpSalala(
        tester,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        seedPlacements: <Placement>[
          _handover(
            id: 'p-1',
            placed: _placedOn,
            buyerId: null,
            contract: 'old.pdf-8',
          ),
        ],
        contractFiles: contracts,
      );
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Buyer not recorded'));

      await _tap(tester, sectionText('Buyer not recorded'));
      await _tap(tester, find.byTooltip('Remove the contract'));
      await _cancelDialog(tester, 'Edit placement');

      expect(contracts.deleted, isEmpty);
      // The row still names it, so the tile still offers it.
      expect(find.byTooltip('Open the contract'), findsOneWidget);
    });

    testWidgets('a picker that refuses says so and changes nothing', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final contracts = FakeContractFiles()
        ..pickFailure = StateError('no picker');
      await pumpSalala(
        tester,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        contractFiles: contracts,
      );
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, sectionText('Placements'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
      await _tap(tester, attachRow());

      expect(sectionText('No document could be chosen'), findsOneWidget);
      expect(sectionText('Attach a contract'), findsOneWidget);
    });
  });
}

int _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
