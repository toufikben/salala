import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/schema.dart';
import 'package:salala/core/utils/date_utils.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/photo.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/presentation/screens/animal_list_screen.dart';
import 'package:salala/presentation/widgets/animal_card.dart';
import 'package:salala/services/data_pack.dart';
import 'package:salala/services/pack_archive.dart';
import 'package:salala/services/pack_files.dart';

import '../helpers/fake_notification_writer.dart';
import '../helpers/fake_pack_files.dart';
import '../helpers/fake_photo_files.dart';
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
  List<Map<String, Object?>>? photos,
  List<Map<String, Object?>> settings = const <Map<String, Object?>>[],
  int formatVersion = packFormatVersion,
}) {
  final rows = <String, Object?>{
    for (final table in dataTables) table: const <Object?>[],
  };
  rows['animals'] = animals;
  rows['vaccinations'] = vaccinations;
  // The settings travel with the pack, language included — which is why a
  // restore has to do something about the language rather than assume the row
  // on screen is the row that arrived.
  rows['user_settings'] = settings;
  // Null is a pack from before pictures existed; a list is a pack whose rows
  // travel with their bytes in the archive.
  if (photos != null) rows['photos'] = photos;
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

/// The herd tab, scrolled until the named card has been built.
///
/// A card is a photograph now, so two animals are taller than a phone's screen
/// and the list is lazy: a card below the fold does not exist yet, and looking
/// for it without scrolling finds nothing even when the row is in the ledger.
Future<void> scrollHerdTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find
        .descendant(
          of: find.byType(AnimalListScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
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
      // screen promises: a pack, stamped to the minute, in a container that says
      // it holds pictures as well as rows.
      expect(
        files.shared.keys.single,
        matches(r'^salala-pack-\d{8}-\d{4}\.zip$'),
      );
      expect(find.textContaining('is ready to send'), findsOneWidget);
    });

    testWidgets('the file carries the pictures as well as the rows', (
      tester,
    ) async {
      final photos = FakePhotoFiles(
        bytes: <String, List<int>>{
          'atlas/1759000000000-4.jpg': <int>[7, 7, 7],
        },
      );
      await pumpSalala(
        tester,
        packFiles: files,
        photoFiles: photos,
        seed: <Animal>[animal('Atlas')],
        seedPhotos: <Photo>[
          Photo(
            id: 'p-1',
            animalId: 'atlas',
            fileName: '1759000000000-4.jpg',
            createdAt: 1759000000000,
          ),
        ],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Export records');

      // The bytes travel beside the ledger: a restore on a new phone gets the
      // images, not just their file names.
      expect(files.sharedPhotos, <String, List<int>>{
        'atlas/1759000000000-4.jpg': <int>[7, 7, 7],
      });
      final rows =
          (jsonDecode(files.sharedJson) as Map<String, Object?>)['rows']
              as Map<String, Object?>;
      expect(rows['photos'], hasLength(1));
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
      // Keyed on the sentence rather than on a fixed pump: the restore is a
      // transaction, a resync, a sweep and two refreshes deep, and a snackbar at
      // the end of that chain lands whenever the database isolate answers. Run
      // `38167035402` measured the alternative — the same green test read 0
      // snackbars after a photo row was added to the transaction, because
      // `settleRealIo`'s rounds ran out one step before the last one.
      await settleRefusal(tester, waitingFor: 'Records restored: 3');

      expect(find.text('Records restored: 3'), findsOneWidget);

      await goTo(tester, 'Animals');
      // The whole phone moved, not just the rows the pack added: Atlas was here
      // and the pack says she is not, so she is gone.
      //
      // Scoped to the cards: a restored dose due inside a fortnight puts its
      // animal's name in the agenda above the herd too, so the restored herd is
      // two rows per animal on this screen, not one.
      //
      // Scrolled to, one name at a time: a card is a photograph now, so the
      // second animal sits below the fold in a lazy list.
      for (final name in const <String>['Kenza', 'Sultan']) {
        final card = find.descendant(
          of: find.byType(AnimalCard),
          matching: find.text(name),
        );
        await scrollHerdTo(tester, card);
        expect(card, findsOneWidget);
      }
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

    testWidgets('the restore tells the folder which pictures still belong', (
      tester,
    ) async {
      final photos = FakePhotoFiles();
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('atlas', 'Atlas')],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        photoFiles: photos,
        seed: <Animal>[animal('Atlas')],
        seedPhotos: <Photo>[
          Photo(
            id: 'p-1',
            animalId: 'atlas',
            fileName: '1759000000000-4.jpg',
            createdAt: 1759000000000,
          ),
        ],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      // The sweep is not the last thing the restore does, so this waits for the
      // sentence that is: once the chain has reached the snackbar, the call below
      // it has certainly happened or certainly been refused.
      await settleRefusal(tester, waitingFor: 'Records restored: 1');
      // And then for the sweep itself, rather than assuming it landed with the
      // sentence: on a loaded machine the folder call is a real file-system hop
      // after the row that announced it, and the fixed rounds above end when the
      // snackbar appears, not when the disk answered.
      await settleUntil(tester, () => photos.sweeps.isNotEmpty);

      // A pack carries no pictures, so the rows that came through are the only
      // answer to which bytes still belong on this phone. Without this call a
      // restore leaves a photograph named by nothing — invisible to every screen,
      // so nothing but an uninstall could ever remove it.
      expect(photos.sweeps, hasLength(1));
      expect(photos.sweeps.single, <String, Set<String>>{
        'atlas': <String>{'1759000000000-4.jpg'},
      });
    });

    testWidgets(
      'a pack with pictures puts the bytes back and keeps their rows',
      (tester) async {
        final photos = FakePhotoFiles();
        files.picked = PickedPackFile(
          name: 'salala-pack.zip',
          bytes: encodePackArchive(
            packJson(
              animals: <Map<String, Object?>>[animalRow('atlas', 'Atlas')],
              photos: <Map<String, Object?>>[
                <String, Object?>{
                  'id': 'p-1',
                  'animal_id': 'atlas',
                  'file_name': '1759000000000-4.jpg',
                  'created_at': 1759000000000,
                },
              ],
            ),
            <String, List<int>>{
              'atlas/1759000000000-4.jpg': <int>[7, 7, 7],
            },
          ),
        );
        await pumpSalala(tester, packFiles: files, photoFiles: photos);
        await goTo(tester, 'Settings');

        await tapTile(tester, 'Restore from a pack');
        await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
        await settleRefusal(tester, waitingFor: 'Records restored: 2');

        // The picture is written, its row comes from the pack, and the sweep keeps
        // exactly that file — a restore that left the bytes behind would show the
        // blank this app draws for a picture the phone does not have.
        expect(photos.restored, <String>['atlas/1759000000000-4.jpg']);
        expect(photos.sweeps.single, <String, Set<String>>{
          'atlas': <String>{'1759000000000-4.jpg'},
        });
      },
    );

    testWidgets('a phone that refuses the sweep still restored the ledger', (
      tester,
    ) async {
      final photos = FakePhotoFiles()..sweepFailure = StateError('busy');
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
      );
      await pumpSalala(tester, packFiles: files, photoFiles: photos);
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await settleRefusal(tester, waitingFor: 'Records restored: 1');

      // The records are the win. A folder the phone will not clear is a log
      // line, not a message that says the restore failed when it did not.
      expect(find.text('Records restored: 1'), findsOneWidget);
      expect(photos.sweeps, isEmpty);
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

    testWidgets('a restore does not inherit the other phone\'s backup day', (
      tester,
    ) async {
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
        // A stamp already on this phone, so the assertion is about what the
        // restore does to it rather than about a row that was never there.
        beforeLaunch: (db) => db.insert('user_settings', <String, Object?>{
          'key': 'last_pack_exported_at',
          'value': '${DateTime(2026, 1, 1).millisecondsSinceEpoch}',
          'updated_at': 0,
        }),
      );
      await goTo(tester, 'Settings');

      // The stamp from before the restore, formatted the way the row writes it.
      final staleDay = formatDayFor(
        'en',
        DateTime(2026, 1, 1).millisecondsSinceEpoch,
      );
      expect(find.text('Last backup: $staleDay'), findsOneWidget);

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await settleRefusal(tester, waitingFor: 'Records restored: 1');
      await settleRealIo(tester);

      // The pack came from a phone whose habit is not this phone's: a day
      // inherited from a ledger that was never here is a claim nobody can check.
      expect(find.text('No backup has left this phone yet'), findsOneWidget);
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
      await settleRefusal(tester, waitingFor: appLockRefusalSentence);

      expect(find.text(appLockRefusalSentence), findsOneWidget);
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
      // The tap writes the row and the app only repaints in the new language
      // once that write lands, so the sentence is the thing to wait for — a
      // fixed pair of settles passed alone and failed inside a suite, where the
      // write was still in another isolate when the assertion ran.
      await settleUntil(tester, () => find.text('اللغة').evaluate().isNotEmpty);

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
      await settleRefusal(tester, waitingFor: languageRefusalSentence);

      expect(find.text(languageRefusalSentence), findsOneWidget);
      // The choice was never stored, so the screen must not wear it: before this
      // order the app went Arabic for the session and English the next morning,
      // with no sentence anywhere between the two to say the tap had failed.
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('اللغة'), findsNothing);
    });

    testWidgets('every language the app ships is offered', (tester) async {
      // The list in Settings used to be four codes typed by hand, which meant a
      // fifth `.arb` file shipped a language nobody could choose. The menu is
      // read off the delegate now, so this test is the guard on that promise:
      // whatever `supportedLocales` holds has to be reachable from this row.
      // Counted rather than named, so adding a language does not mean editing
      // this test — which is the whole point of the menu reading the delegate.
      await pumpSalala(tester, seed: <Animal>[animal('Atlas')]);
      await goTo(tester, 'Settings');
      await tapTile(tester, 'Language');

      expect(
        find.byType(MenuItemButton),
        findsNWidgets(AppLocalizations.supportedLocales.length + 1),
        reason:
            'the menu offers ${AppLocalizations.supportedLocales.length} '
            'language(s) plus System default, and the row drew a different '
            'number: a shipped .arb file that cannot be chosen, or an entry '
            'that has no .arb file behind it',
      );
      expect(
        find.descendant(
          of: find.byType(MenuItemButton),
          matching: find.text('System default'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a language added after the first three changes the app', (
      tester,
    ) async {
      // Picking German rather than Arabic on purpose: the three original
      // languages would pass this test even if the menu were still hardcoded.
      await pumpSalala(tester, seed: <Animal>[animal('Atlas')]);
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Language');
      await tester.tap(find.text('Deutsch'));
      await settleUntil(
        tester,
        () => find.text('Sprache').evaluate().isNotEmpty,
      );

      expect(find.text('Sprache'), findsOneWidget);
    });

    testWidgets('a restore adopts the language the pack was read in', (
      tester,
    ) async {
      // `user_settings` travels whole, so the pack arrives with the other
      // phone's language. The app read that setting once, in `main()`, before
      // the first frame — so a restore that only puts the rows back leaves the
      // ledger in one language and every label around it in another, until the
      // next launch quietly fixes it.
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
        settings: <Map<String, Object?>>[
          <String, Object?>{
            'key': 'language_code',
            'value': 'de',
            'updated_at': 0,
          },
        ],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
      );
      await goTo(tester, 'Settings');

      await tapTile(tester, 'Restore from a pack');
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await settleRefusal(tester, waitingFor: 'Records restored: 2');
      // The snackbar was built from the sentences the screen held when the tap
      // landed, so it stays English; the app under it does not.
      await settleUntil(
        tester,
        () => find.text('Sprache').evaluate().isNotEmpty,
      );

      expect(find.text('Sprache'), findsOneWidget);
      expect(find.text('Language'), findsNothing);
    });

    testWidgets('a pack that says system hands the app back to the phone', (
      tester,
    ) async {
      // The other half of the same rule: `system` is a value this app stores but
      // not a language it can show, so adopting it has to mean "no override"
      // rather than a `Locale('system')` that resolves to nothing.
      files.pickedText = packJson(
        animals: <Map<String, Object?>>[animalRow('a-1', 'Kenza')],
        settings: <Map<String, Object?>>[
          <String, Object?>{
            'key': 'language_code',
            'value': 'system',
            'updated_at': 0,
          },
        ],
      );
      await pumpSalala(
        tester,
        packFiles: files,
        seed: <Animal>[animal('Atlas')],
        locale: const Locale('ar'),
      );
      await goTo(tester, 'الإعدادات');

      await tapTile(tester, 'استرجاع من حزمة');
      await tester.tap(find.widgetWithText(FilledButton, 'استبدال'));
      await settleRefusal(tester, waitingFor: 'عدد السجلات المسترجعة: 2');
      await settleUntil(
        tester,
        () => find.text('Language').evaluate().isNotEmpty,
      );
      expect(find.text('Language'), findsOneWidget);
    });
  });
}
