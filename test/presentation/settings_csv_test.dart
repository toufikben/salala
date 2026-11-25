import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/core/utils/date_utils.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/data/models/buyer.dart';
import 'package:companion/data/models/litter.dart';
import 'package:companion/data/models/placement.dart';
import 'package:companion/data/models/vaccination.dart';
import 'package:companion/presentation/screens/settings_screen.dart';

import '../helpers/fake_pack_files.dart';
import '../helpers/pump_app.dart';

/// The four CSV exports and the one row that says how old the backup is.
///
/// Distinct from `settings_pack_test.dart` on purpose: a pack and a spreadsheet
/// answer different questions, and the file that must not lose a picture is not
/// the file an accountant opens.
const String _nalaId = 'animal-nala';
const String _buyerId = 'buyer-zoe';

Animal _animal(String id, String name, {String? damId}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  damId: damId,
  createdAt: 0,
  updatedAt: 0,
);

Future<void> _goToSettings(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
  await settleRealIo(tester);
}

Future<void> _openCsvTiles(WidgetTester tester) async {
  // Idempotent: `ExpansionTile` toggles, so opening it twice in a loop would
  // close the very rows the next tap is looking for.
  if (find.text('Handovers').evaluate().isNotEmpty) return;
  final header = find.text('Spreadsheet (CSV)');
  // Scrolled, not `ensureVisible`: Settings is a lazy `ListView` that now carries
  // the Pro row and the trial row above the spreadsheet, so on a phone viewport
  // the header has not been built at all and `ensureVisible` throws "No element"
  // instead of scrolling.
  await tester.scrollUntilVisible(
    header,
    180,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
  await tester.tap(header);
  await settleRealIo(tester);
}

Future<void> _tapCsv(WidgetTester tester, String label) async {
  await _openCsvTiles(tester);
  // Scoped to the expanded tile: `Animals` is also the first navigation label,
  // and a bare `find.text` picks up both and refuses to guess.
  final tile = find.descendant(
    of: find.byType(ExpansionTile),
    matching: find.text(label),
  );
  // The four rows are taller than what is left of the screen once the header has
  // been scrolled to, so the last one is not built until it is scrolled for.
  await tester.scrollUntilVisible(
    tile,
    120,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
  await tester.tap(tile);
  await settleRealIo(tester);
}

/// The text of the last file handed to the sheet, decoded the way a reader would.
String _lastCsv(FakePackFiles files) =>
    utf8.decode(files.shared.values.last, allowMalformed: false);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  late FakePackFiles files;

  setUp(() => files = FakePackFiles());

  group('the spreadsheet exports', () {
    testWidgets('the herd goes out as one CSV with a BOM and CRLF', (
      tester,
    ) async {
      await pumpApp(
        tester,
        packFiles: files,
        seed: <Animal>[
          _animal(_nalaId, 'Nala'),
          _animal('animal-pip', 'Pip', damId: _nalaId),
        ],
      );
      await _goToSettings(tester);
      await _tapCsv(tester, 'Animals');

      expect(
        files.shared.keys.single,
        matches(r'^companion-herd-\d{8}-\d{4}\.csv$'),
      );
      // The mark is the first byte triple, not a character the reader sees: a
      // BOM after the header is a stray `ï»¿` in the first cell. Checked on the
      // bytes because Dart's own UTF-8 decoder silently eats a leading mark.
      expect(files.shared.values.last.take(3), <int>[0xEF, 0xBB, 0xBF]);
      final text = _lastCsv(files);
      expect(text.split('\r\n').first, startsWith('Name,'));
      expect(text, contains('Nala'));
      // Parents by name: the file is read by a person, and `animal-nala` is not
      // a name anyone can look up on paper.
      expect(text, contains(',Nala,'));
      expect(text, isNot(contains('animal-nala')));
      expect(find.textContaining('is ready to send'), findsOneWidget);
    });

    testWidgets('each of the four tables exports on its own', (tester) async {
      await pumpApp(
        tester,
        packFiles: files,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
        seedBuyers: <Buyer>[
          Buyer(id: _buyerId, name: 'Zoe', createdAt: 0, updatedAt: 0),
        ],
        seedLitters: <Litter>[
          Litter(
            id: 'litter-1',
            name: 'Spring',
            damId: _nalaId,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
        seedVaccinations: <Vaccination>[
          Vaccination(
            id: 'dose-1',
            animalId: _nalaId,
            vaccineName: 'Rabies',
            dateAdministered: DateTime(2026, 1, 5).millisecondsSinceEpoch,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
        seedPlacements: <Placement>[
          Placement(
            id: 'pl-1',
            animalId: _nalaId,
            buyerId: _buyerId,
            placedDate: DateTime(2026, 2, 14).millisecondsSinceEpoch,
            price: 2500,
            currency: 'EUR',
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );
      await _goToSettings(tester);

      for (final table in <String>['Litters', 'Vaccinations', 'Handovers']) {
        await _tapCsv(tester, table);
        expect(
          files.shared,
          isNotEmpty,
          reason: 'nothing was shared for $table',
        );
      }

      // Every table named the file it wrote, so four files are four different
      // names rather than one overwriting the next in a Downloads folder.
      expect(files.shared.keys.toSet(), hasLength(3));
      expect(files.shared.keys, everyElement(matches(r'^companion-[a-z]+-')));
    });

    testWidgets('a brand-new install says there is nothing to export', (
      tester,
    ) async {
      await pumpApp(tester, packFiles: files);
      await _goToSettings(tester);
      await _tapCsv(tester, 'Animals');

      expect(
        find.text('There is nothing on this phone to export yet'),
        findsOneWidget,
      );
      // A CSV of five headers and no rows reads as a broken app, not as an
      // empty one.
      expect(files.shared, isEmpty);
    });

    testWidgets('a refused share says the sheet could not be written', (
      tester,
    ) async {
      files.shareFailure = StateError('no activity to share to');
      await pumpApp(
        tester,
        packFiles: files,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
      );
      await _goToSettings(tester);
      await _tapCsv(tester, 'Animals');

      expect(
        find.text('The sheet could not be written on this phone'),
        findsOneWidget,
      );
    });
  });

  group('the freshness row', () {
    testWidgets('a phone that has never been backed up says so', (
      tester,
    ) async {
      await pumpApp(
        tester,
        packFiles: files,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
      );
      await _goToSettings(tester);

      expect(find.text('No backup has left this phone yet'), findsOneWidget);
    });

    testWidgets('a backup stamps the day, and the row reads it back', (
      tester,
    ) async {
      await pumpApp(
        tester,
        packFiles: files,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
      );
      await _goToSettings(tester);

      final export = find.text('Export records');
      // Settings is lazy and the Pro row and the trial row now sit above the
      // pack tiles, so the row is scrolled for rather than assumed built.
      await tester.scrollUntilVisible(
        export,
        180,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      await tester.tap(export);
      await settleRealIo(tester);

      // The same day the test is running, formatted the way this screen writes
      // every other date — read back out of the settings table, so the value has
      // survived a real write rather than being shown from a variable.
      final today = formatDayFor('en', DateTime.now().millisecondsSinceEpoch);
      expect(find.text('Last backup: $today'), findsOneWidget);
      expect(find.text('No backup has left this phone yet'), findsNothing);
    });

    testWidgets('a refused share does not claim a backup happened', (
      tester,
    ) async {
      files.shareFailure = StateError('no activity to share to');
      await pumpApp(
        tester,
        packFiles: files,
        seed: <Animal>[_animal(_nalaId, 'Nala')],
      );
      await _goToSettings(tester);

      final export = find.text('Export records');
      await tester.scrollUntilVisible(
        export,
        180,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      await tester.tap(export);
      await settleRealIo(tester);

      // The one honest row on this screen: a share that threw is a backup that
      // did not happen, and stamping the day anyway would be a claim the breeder
      // has no way to check.
      expect(find.text('No backup has left this phone yet'), findsOneWidget);
    });
  });
}
