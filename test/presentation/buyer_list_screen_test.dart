import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/data/models/buyer.dart';
import 'package:companion/data/models/placement.dart';

import '../helpers/pump_app.dart';

/// The contact list: the one screen in this app whose subject is a person rather
/// than an animal, and the only place a breeder can answer "what did I sell this
/// one" without already knowing which dog to open.
const String _nalaId = 'animal-nala';
const String _zidaId = 'animal-zida';
const String _buyerId = 'buyer-zoe';

Animal _animal(String id, String name) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  createdAt: 0,
  updatedAt: 0,
);

Buyer _buyer({
  String id = _buyerId,
  String name = 'Zoé Martin',
  String? phone,
  String? email,
  String? country,
}) => Buyer(
  id: id,
  name: name,
  phone: phone,
  email: email,
  countryCode: country,
  createdAt: 0,
  updatedAt: 0,
);

Placement _placement(String animalId, {String? buyerId = _buyerId, int? day}) =>
    Placement(
      id: 'pl-$animalId',
      animalId: animalId,
      buyerId: buyerId,
      placedDate: day ?? DateTime(2026, 2, 14).millisecondsSinceEpoch,
      createdAt: 0,
      updatedAt: 0,
    );

Future<void> _openBuyers(WidgetTester tester) async {
  final tab = find.widgetWithText(NavigationDestination, 'Buyers');
  await tester.tap(tab);
  await settleRealIo(tester);
}

Future<void> _expectNoFlutterErrors(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('the contact list shows a buyer with the animals they took', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala'), _animal(_zidaId, 'Zida')],
      seedBuyers: <Buyer>[_buyer(phone: '+33 6 12 34 56 78', country: 'FR')],
      seedPlacements: <Placement>[_placement(_nalaId)],
    );
    await _openBuyers(tester);

    expect(find.text('Zoé Martin'), findsOneWidget);
    // The contact details come before the dogs, and the dog they took is named:
    // the screen has to answer both "how do I reach them" and "what did I sell".
    expect(find.textContaining('+33 6 12 34 56 78'), findsOneWidget);
    expect(find.textContaining('Nala'), findsWidgets);
    expect(find.textContaining('Zida'), findsNothing);
    await _expectNoFlutterErrors(tester);
  });

  testWidgets('a contact with no handover is still on the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_buyer(name: 'Sami')],
    );
    await _openBuyers(tester);

    // A person added before the sale — the one from last year who still wants
    // the pedigree — must not be invisible until an animal is attached.
    expect(find.text('Sami'), findsOneWidget);
    expect(find.text('No animal on file for this contact'), findsOneWidget);
    await _expectNoFlutterErrors(tester);
  });

  testWidgets('an empty list offers the way out of being empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
    await _openBuyers(tester);

    expect(find.text('No buyers yet'), findsOneWidget);
    // The FAB and the button in the middle are the same action; the middle one
    // is what a thumb reaches on an empty screen.
    expect(find.widgetWithText(FilledButton, 'New buyer'), findsOneWidget);
    await _expectNoFlutterErrors(tester);
  });

  testWidgets('a new buyer is written and appears without a reload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(tester, seed: <Animal>[_animal(_nalaId, 'Nala')]);
    await _openBuyers(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New buyer'));
    await settleRealIo(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Nadia Haddad',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      '+212 600 111 222',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    // Keyed on the form closing: a write that landed dismisses it, and the list
    // behind it only shows the name once the write and its refresh have both
    // answered — which on a loaded machine can outlast the fixed rounds.
    await settleUntil(
      tester,
      () =>
          find.widgetWithText(FilledButton, 'New buyer').evaluate().isNotEmpty,
    );
    await settleRealIo(tester);

    expect(find.text('Nadia Haddad'), findsOneWidget);
    expect(find.text('No buyers yet'), findsNothing);
    await _expectNoFlutterErrors(tester);
  });

  testWidgets('correcting a name keeps the animal it is attached to', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_buyer(name: 'Zoe Martin')],
      seedPlacements: <Placement>[_placement(_nalaId)],
    );
    await _openBuyers(tester);

    await tester.tap(find.text('Zoe Martin'));
    await settleRealIo(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Zoé Martin',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleRealIo(tester);

    // A rename is an edit of the contact, not a new contact plus a lost sale.
    expect(find.text('Zoé Martin'), findsOneWidget);
    expect(find.text('Zoe Martin'), findsNothing);
    expect(find.textContaining('Nala'), findsWidgets);
    await _expectNoFlutterErrors(tester);
  });

  testWidgets('deleting a contact keeps the handover on the animal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      seed: <Animal>[_animal(_nalaId, 'Nala')],
      seedBuyers: <Buyer>[_buyer()],
      seedPlacements: <Placement>[_placement(_nalaId)],
    );
    await _openBuyers(tester);

    await tester.tap(find.text('Zoé Martin'));
    await settleRealIo(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settleRealIo(tester);
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleUntil(
      tester,
      () => find.widgetWithText(FilledButton, 'Save').evaluate().isEmpty,
    );
    await settleRealIo(tester);

    expect(find.text('Zoé Martin'), findsNothing);
    expect(find.text('No buyers yet'), findsOneWidget);

    // The sale is the breeder's record and survives the person asking to be
    // forgotten — that is exactly what the confirmation sentence promised.
    final tab = find.widgetWithText(NavigationDestination, 'Animals');
    await tester.tap(tab);
    await settleRealIo(tester);
    expect(find.text('Nala'), findsWidgets);
    await _expectNoFlutterErrors(tester);
  });
}
