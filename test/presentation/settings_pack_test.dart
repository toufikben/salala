import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/schema.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/presentation/widgets/animal_card.dart';
import 'package:salala/services/data_pack.dart';

import '../helpers/fake_notification_writer.dart';
import '../helpers/fake_pack_files.dart';
import '../helpers/pump_app.dart';

/// A pack with every table present, so [parsePack] accepts it, holding only the
/// rows a test cares about.
///
/// Hand-written rather than exported from a second database because what these
/// tests are about is what the screen does with a file the phone handed it —
/// which includes one from an older build, another app, or a text message.
String packJson({
  List<Map<String, Object?>> animals = const <Map<String, Object?>>[],
  List<Map<String, Object?>> vaccinations = const <Map<String, Object?>>[],
  int formatVersion = packFormatVersion,
}) {
  final rows = <String, Object?>{
    for (final table in dataTables) table: const <Object?>[],
  };
  rows['animals'] = animals;
  rows['vaccinations'] = vaccinations;
  return jsonEncode(<String, Object?>{
    'format': packFormat,
    'formatVersion': formatVersion,
    'schemaVersion': schemaVersion,
    'exportedAt': 1759000000000,
    'rows': rows,
  });
}

Map<String, Object?> animalRow(String id, String name) => <String, Object?>{
  'id': id,
  'name': name,
  'species': 'dog',
  'sex': 'female',
  'status': 'active',
  'is_breeding_stock': 0,
  'created_at': 1759000000000,
  'updated_at': 1759000000000,
};

Map<String, Object?> doseRow(String id, String animalId, int dueMs) =>
    <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'vaccine_name': 'Rabies',
      'date_administered': dueMs - 86400000 * 10,
      'next_due_date': dueMs,
      'created_at': dueMs,
      'updated_at': dueMs,
    };

Animal animal(String name, {bool breeding = false}) => Animal(
  // A supplied id is kept by the dao, which is what lets a dose point at the
  // animal it belongs to instead of at a uuid nobody can predict.
  id: name.toLowerCase(),
  name: name,
  species: 'dog',
  sex: Sex.male,
  status: AnimalStatus.active,
  isBreedingStock: breeding,
  createdAt: 0,
  updatedAt: 0,
);

Vaccination dose(String animalId) => Vaccination(
  id: '',
  animalId: animalId,
  vaccineName: 'Rabies',
  dateAdministered: DateTime.now().millisecondsSinceEpoch,
  createdAt: 0,
  updatedAt: 0,
);

Future<void> goTo(WidgetTester tester, String destination) async {
  await tester.tap(find.widgetWithText(NavigationDestination, destination));
  await settleRealIo(tester);
}

Future<void> tapTile(WidgetTester tester, String title) async {
  // A tile's label can sit under the snackbar the previous action left behind,
  // so the scroll is asserted rather than assumed.
  final tile = find.text(title);
  await tester.ensureVisible(tile);
  await tester.pump();
  await tester.tap(tile);
  await settleRealIo(tester);
}

void main() {
  // A tap that misses its widget must fail the test instead of only warning;
  // a missed tap once produced a green test that had saved nothing.
  WidgetController.hitTestWarningShouldBeFatal = true;

  late FakePackFiles files;

  setUp(() => files = FakePackFiles());

  group('exporting', () {
    testWidgets('hands the sheet every record on the phone', (tester) async {
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas'), animal('Zida', breeding: true)],
        seedVaccinations: <Vaccination>[dose('atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Export records');

      final rows =
          (jsonDecode(files.sharedJson) as Map<String, Object?>)['rows']
              as Map<String, Object?>;
      expect(rows['animals'], hasLength(2));
      expect(rows['vaccinations'], hasLength(1));
      // The name is the breeder's handle on the file, so it is part of what the
      // screen promises: a pack, stamped to the minute, that says it is JSON.
      expect(
        files.shared.keys.single,
        matches(r'^salala-pack-\d{8}-\d{4}\.json$'),
      );
      expect(find.textContaining('is ready to send'), findsOneWidget);
    });

    testWidgets('a phone that refuses the sheet says so', (tester) async {
      files.shareFailure = StateError('no activity to share to');
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Export records');

      expect(
        find.text('The pack could not be written on this phone'),
        findsOneWidget,
      );
      expect(files.shared, isEmpty);
    });
  });

  group('restoring', () {
    testWidgets('names what it is about to destroy before it asks', (
      tester,
    ) async {
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[
          animalRow('a-1', 'Kenza'),
          animalRow('a-2', 'Sultan'),
        ],
        vaccinations: <Map<String, Object?>>[doseRow('v-1', 'a-1', 1)],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Replace everything on this phone?'), findsOneWidget);
      // Counts, not a vague promise: how many animals, how many records, and the
      // day the pack was made, so a wrong file is caught here rather than later.
      expect(find.textContaining('Animals: 2'), findsOneWidget);
      expect(find.textContaining('Records: 3'), findsOneWidget);
      // The day itself is checked as a shape, not as one fixed date: the pack
      // holds an instant, and the runner's own timezone decides which day it is.
      expect(
        tester.widget<Text>(find.textContaining('Animals: 2')).data,
        matches(RegExp(r'From [A-Z][a-z]+ [0-9]{1,2}, [0-9]{4}\.')),
      );
    });

    testWidgets('Cancel leaves the ledger exactly as it was', (tester) async {
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await settleRealIo(tester);

      await goTo(tester, 'Animals');
      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Kenza'), findsNothing);
    });

    testWidgets('Replace puts the pack on the phone and shows it', (
      tester,
    ) async {
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[
          animalRow('a-1', 'Kenza'),
          animalRow('a-2', 'Sultan'),
        ],
        vaccinations: <Map<String, Object?>>[doseRow('v-1', 'a-1', 1)],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await settleRealIo(tester);

      expect(find.text('Records restored: 3'), findsOneWidget);

      await goTo(tester, 'Animals');
      // The whole phone moved, not just the rows the pack added: Atlas was here
      // and the pack says she is not, so she is gone.
      //
      // Scoped to the cards: a restored dose due inside a fortnight puts its
      // animal's name in the agenda above the herd too, so the restored herd is
      // two rows per animal on this screen, not one.
      expect(
        find.descendant(
          of: find.byType(AnimalCard),
          matching: find.text('Kenza'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AnimalCard),
          matching: find.text('Sultan'),
        ),
        findsOneWidget,
      );
      expect(find.text('Atlas'), findsNothing);
    });

    testWidgets('re-arms the alarms the incoming records asked for', (
      tester,
    ) async {
      final notifications = FakeNotificationWriter();
      final due = DateTime.now().add(const Duration(days: 20));
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
        vaccinations: <Map<String, Object?>>[
          doseRow('v-1', 'a-1', due.millisecondsSinceEpoch),
        ],
      );
      await pumpSalala(
        tester,
        notifications: notifications,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      // The ledger on the phone is a different one now, and the alarms were
      // booked off the rows that used to be here. Nobody pressed save, so nothing
      // else would have told the phone to stop waking for Atlas and start waking
      // for Kenza.
      await waitForSchedulerCalls(tester, notifications, 4);

      // The emptying comes first: the herd that used to be on this phone may not
      // be in the pack at all, and its alarms have no row left to cancel them by.
      expect(notifications.log, <String>[
        'clearAll',
        'clear',
        'clear',
        'write',
      ]);
      expect(notifications.written, hasLength(1));
      expect(notifications.written.single.title, 'Kenza');
      expect(notifications.written.single.body, contains('Rabies'));
    });

    testWidgets('a file that is not a pack is refused without asking', (
      tester,
    ) async {
      files.pickedText = '{"notes":"a shopping list"}';
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');

      expect(
        find.text('That file is not a Salala pack, or it is damaged'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a pack from a newer Salala is refused', (tester) async {
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
        formatVersion: 99,
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');

      expect(
        find.text('That pack comes from a newer Salala than this one'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a pack missing a table is refused by name', (tester) async {
      final broken = jsonDecode(
        packJson(animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')]),
      ) as Map<String, Object?>;
      (broken['rows']! as Map<String, Object?>).remove('vaccinations');
      files.pickedText = jsonEncode(broken);
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');

      expect(
        find.text('That pack is missing part of the ledger: vaccinations'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('backing out of the picker says nothing', (tester) async {
      files.pickedText = null;
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');

      // Closing the picker is the breeder's own decision, not a fault, so the
      // screen stays put with no message over it.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a file the phone will not open says so', (tester) async {
      files.pickFailure = StateError('permission denied');
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');

      expect(find.text('That file could not be opened'), findsOneWidget);
    });
  });

  group('the app lock', () {
    testWidgets('a phone that refuses the PIN says so', (tester) async {
      final storage = await pumpSalala(tester, seed: <Animal>[animal('Atlas')]);
      await goTo(tester, 'Settings');

      // Refused on the second write, which is the interesting half: the salt is
      // already in the keystore by then. Before this test the exception simply
      // ended the tap handler, so the switch snapped back and the breeder read
      // a broken tile and tapped it again.
      storage.writeRefused.add('app_lock_digest');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your PIN'),
        '2481',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Repeat the PIN'),
        '2481',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settleRefusal(tester);

      expect(
        find.text('The phone would not change the app lock.'),
        findsOneWidget,
      );
      expect(
        tester.widget<Switch>(find.byType(Switch)).value,
        isFalse,
        reason: 'a lock the phone refused is not a lock the breeder has',
      );
      expect(storage.values['app_lock_digest'], isNull);
    });
  });

  group('the language', () {
    // The pair exists because the second test's "still English" means nothing
    // unless the first one shows the same tap does move the app when the phone
    // accepts the row.
    testWidgets('a language the phone stored changes the whole app', (
      tester,
    ) async {
      await pumpSalala(tester, seed: <Animal>[animal('Atlas')]);
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Language');
      await tester.tap(find.text('العربية'));
      await settleRealIo(tester);
      await tester.pumpAndSettle();

      expect(find.text('اللغة'), findsOneWidget);
    });

    testWidgets('a language the phone will not store is not shown as chosen', (
      tester,
    ) async {
      await pumpSalala(
        tester,
        seed: <Animal>[animal('Atlas')],
        beforeLaunch: refuseWritesTo('user_settings'),
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Language');
      await tester.tap(find.text('العربية'));
      await settleRefusal(tester);

      expect(
        find.text('The phone would not keep this language.'),
        findsOneWidget,
      );
      // The choice was never stored, so the screen must not wear it: before this
      // order the app went Arabic for the session and English the next morning,
      // with no sentence anywhere between the two to say the tap had failed.
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('اللغة'), findsNothing);
    });
  });
}
