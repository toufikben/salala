import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';
import 'package:salala/presentation/widgets/placement_dialog.dart';

import '../helpers/pump_app.dart';

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
}) => Placement(
  id: id,
  animalId: animalId,
  buyerId: buyerId,
  placedDate: placed,
  price: price,
  currency: currency,
  guaranteeTerms: guarantee,
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
  await tester.tap(find.text(name));
  await settleRealIo(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
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
  await tester.pumpAndSettle();
}

/// Taps the Save button of one open dialog.
///
/// Scoped by title because the placement form and the contact form are stacked
/// on each other for part of this flow, and both end in a FilledButton that
/// reads "Save": an unscoped finder would tap whichever one the widget tree
/// happens to visit first, and the test would save the wrong record.
Future<void> _saveIn(WidgetTester tester, String dialogTitle) async {
  final save = find.descendant(
    of: find.widgetWithText(AlertDialog, dialogTitle),
    matching: find.widgetWithText(FilledButton, 'Save'),
  );
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  // The row is written through SQLite, and both the contact list and this
  // animal's placements re-read themselves afterwards.
  await settleRealIo(tester);
  await settleRealIo(tester);
}

/// Names a buyer in the contact form and saves it, leaving the placement form
/// with that contact selected.
Future<void> _createBuyer(WidgetTester tester, String name) async {
  await _tap(tester, find.byTooltip('New buyer'));
  expect(find.text('Add a buyer'), findsOneWidget);
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
    await _scrollTo(tester, find.text('Placements'));

    expect(find.text('Placements'), findsOneWidget);
    expect(find.text('Add placement'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'Placements'),
        matching: find.text('Nothing recorded yet.'),
      ),
      findsOneWidget,
    );
    // The absence is the row's own wording, so an empty section cannot be
    // confused for a placement whose buyer was never named.
    expect(find.text('Buyer not recorded'), findsNothing);
  });

  testWidgets(
    'a placement written through the form appears and survives reopening',
    (tester) async {
      _usePhoneViewport(tester);
      await pumpSalala(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, find.text('Placements'));

      await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
      expect(find.text('Log a placement'), findsOneWidget);

      await _createBuyer(tester, 'Aicha');
      // The contact form closed and the handover form is holding the buyer it
      // just wrote — the id the dao assigned, not one typed by hand.
      expect(find.text('Aicha'), findsOneWidget);

      await _priceAndSave(
        tester,
        'Log a placement',
        price: '2500',
        currency: 'mad',
        guarantee: 'Health guarantee for 15 days',
      );

      expect(find.text('Log a placement'), findsNothing);
      await _scrollTo(tester, find.text('Aicha'));
      expect(find.text('Aicha'), findsOneWidget);
      // The amount is printed ungrouped with the code upper-cased by the form,
      // and the day defaults to the one it was written on.
      expect(find.textContaining('2500 MAD'), findsOneWidget);

      // Back to the herd and into the same ledger again: the row has to come
      // off SQLite, not out of a provider the screen happened to keep.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settleRealIo(tester);
      expect(find.byType(AnimalDetailScreen), findsNothing);

      await _openAnimal(tester, 'Nala');
      await _scrollTo(tester, find.text('Aicha'));
      expect(find.text('Aicha'), findsOneWidget);
      expect(
        find.textContaining('Health guarantee for 15 days'),
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
    await _scrollTo(tester, find.text('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await _createBuyer(tester, 'Aicha');
    await _saveIn(tester, 'Log a placement');
    await _scrollTo(tester, find.text('Aicha'));
    expect(find.text('Aicha'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await settleRealIo(tester);
    await _openAnimal(tester, 'Atlas');
    await _scrollTo(tester, find.text('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await _tap(tester, find.byType(DropdownButtonFormField<String?>));
    // A contact list, not a per-animal field: the same family takes the second
    // litter, and the name typed for Nala is a choice here without being
    // typed again.
    expect(find.text('Aicha'), findsOneWidget);
    await _tap(tester, find.text('Aicha'));
    await _saveIn(tester, 'Log a placement');

    await _scrollTo(tester, find.text('Aicha'));
    // On Atlas's ledger, with the form closed: the contact came back out of
    // SQLite after the first screen was thrown away, not out of a provider
    // this route kept.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Aicha'), findsOneWidget);
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
    await _scrollTo(tester, find.text('Aicha'));

    expect(
      find.text(
        _rowDetails(
          localeTag: 'en',
          placed: _placedOn,
          amount: '2500 MAD',
          guarantee: 'Health guarantee for 15 days',
        ),
      ),
      findsOneWidget,
    );

    await _tap(tester, find.text('Aicha'));
    expect(find.text('Edit placement'), findsOneWidget);
    // The stored values are in the fields already, so correcting one row does
    // not mean retyping the rest of it.
    expect(find.text('Health guarantee for 15 days'), findsWidgets);

    await _priceAndSave(tester, 'Edit placement', price: '1800');

    await _scrollTo(tester, find.textContaining('1800 MAD'));
    expect(
      find.text(
        _rowDetails(
          localeTag: 'en',
          placed: _placedOn,
          amount: '1800 MAD',
          guarantee: 'Health guarantee for 15 days',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('2500 MAD'), findsNothing);
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
    await _scrollTo(tester, find.text('Buyer not recorded'));

    expect(find.text('Buyer not recorded'), findsOneWidget);

    await _tap(tester, find.text('Buyer not recorded'));
    expect(find.text('Edit placement'), findsOneWidget);
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRealIo(tester);
    await settleRealIo(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Buyer not recorded'), findsNothing);
    await _scrollTo(tester, find.text('Aicha'));
    expect(find.text('Aicha'), findsOneWidget);
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
    await _scrollTo(tester, find.text('عائشة'));

    expect(find.text('التسليم'), findsOneWidget);
    final details = find.text(
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
      await _scrollTo(tester, find.text('Placements'));

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
      await _scrollTo(tester, find.text('Placements'));

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
    await _scrollTo(tester, find.text('Placements'));

    await _tap(tester, find.widgetWithText(TextButton, 'Add placement'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '2500');
    await typeDateIntoPicker(
      tester,
      scope: AlertDialog,
      tile: 0,
      usDay: usDay(_daysAgo(500)),
    );

    await tapSaveAndGetAnswer(tester, dialogTitle: 'Log a placement');

    expect(
      find.text('This date is before this animal was born.'),
      findsOneWidget,
    );
    expect(
      find.text('This could not be saved. Nothing was written.'),
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
}

int _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
