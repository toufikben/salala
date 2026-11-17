import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/services/csv_export.dart';

/// The spreadsheet export, tested on the bytes rather than on a screenshot.
///
/// Three promises are made by this file and none of them is visible in a phone
/// preview: Excel has to read the Arabic correctly (the mark), rows have to end
/// where Excel expects (CRLF), and a cell must never be able to run as a formula.
/// A test that only counted `,` would pass on all three while the file was wrong.
late AppLocalizations l10n;
Animal _animal(
  String id,
  String name, {
  String? breed,
  String? registrationNo,
  String? microchipId,
  String? notes,
  String? damId,
  String? sireId,
  int? birthDate,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  breed: breed,
  registrationNo: registrationNo,
  microchipId: microchipId,
  notes: notes,
  damId: damId,
  sireId: sireId,
  birthDate: birthDate,
  isBreedingStock: true,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('the file Excel reads', () {
    test('starts with the byte-order mark, then the header', () {
      final csv = csvFile(const <String>['Name', 'Born'], const []);
      expect(csv.codeUnitAt(0), 0xFEFF);
      expect(csv.substring(1), 'Name,Born\r\n');
    });

    test('every row ends in CRLF, not a bare newline', () {
      final csv = csvFile(
        const <String>['Name'],
        <List<String?>>[
          <String?>['Nala'],
          <String?>['Zida'],
        ],
      );

      expect(csv, '${csvBom}Name\r\nNala\r\nZida\r\n');
      expect(csv.replaceAll('\r\n', ''), isNot(contains('\n')));
    });

    test('a missing value is an empty cell, not the word null', () {
      expect(csvCell(null), '');
      expect(csvCell(''), '');
    });
  });

  group('one cell', () {
    test('a plain value is left alone', () {
      expect(csvCell('Nala'), 'Nala');
      // A leading or trailing space is not a reason to quote: Excel would show
      // the same cell either way and the quotes are noise in a diff.
      expect(csvCell('Border collie'), 'Border collie');
    });

    test('a comma, a quote or a newline forces quotes', () {
      expect(csvCell('Nala, Zida'), '"Nala, Zida"');
      expect(csvCell('she said "no"'), '"she said ""no"""');
      expect(csvCell('line one\nline two'), '"line one\nline two"');
      expect(csvCell('line one\r\nline two'), '"line one\r\nline two"');
    });

    test('a value that would run as a formula is prefixed', () {
      // A breeder's note, or a name pasted from a message, is data. A file that
      // executes `=HYPERLINK(...)` when opened does something to the person who
      // asked only to look at their own dogs.
      expect(csvCell('=1+1'), "'=1+1");
      expect(csvCell('@SUM(A1)'), "'@SUM(A1)");
      expect(csvCell('\t=cmd'), "'\t=cmd");
    });

    test('a phone number and a negative amount are not defused', () {
      // `+212…` and `-25` are ordinary data in this ledger, and prefixing them
      // would put stray apostrophes through a column read every day.
      expect(csvCell('+212 600-000000'), '+212 600-000000');
      expect(csvCell('-25.50'), '-25.50');
    });

    test('a defused value that also needs quotes gets both', () {
      expect(csvCell('=A1,B1'), '"\'=A1,B1"');
    });
  });

  group('a stored day', () {
    test('is written yyyy-mm-dd in the phone zone', () {
      final day = DateTime(2026, 3, 9, 13, 45).millisecondsSinceEpoch;
      expect(csvDay(day), '2026-03-09');
    });

    test('is blank when nobody wrote one', () {
      // `1970-01-01` in a registry form is a lie the app invented.
      expect(csvDay(null), '');
    });
  });

  group('the herd sheet', () {
    test('writes the parents by name, not by id', () {
      final animals = <Animal>[
        _animal('a-1', 'Nala'),
        _animal('a-2', 'Atlas', breed: 'Border collie'),
        _animal('a-3', 'Pip', damId: 'a-1', sireId: 'a-2'),
      ];

      final rows = herdCsv(animals, l10n).split('\r\n');
      final pip = rows.firstWhere((row) => row.startsWith('Pip,'));

      // `a-3f9c…` in a Sire column means nothing on paper.
      expect(pip, contains(',Nala,Atlas,'));
      expect(pip, isNot(contains('a-1')));
    });

    test('a parent the pack does not carry is an empty cell', () {
      final animals = <Animal>[_animal('a-3', 'Pip', damId: 'a-missing')];
      expect(herdCsv(animals, l10n).split('\r\n')[1], startsWith('Pip,'));
      expect(
        herdCsv(animals, l10n).split('\r\n')[1],
        isNot(contains('a-missing')),
      );
    });

    test('an empty herd is still a file with its header', () {
      // The headings come off the language now, so this asserts the shape of
      // the header rather than its words: a column count is what a reader of
      // the file depends on, and a heading is what a translator can change.
      final csv = herdCsv(const <Animal>[], l10n);
      final header =
          csvBom +
          csvRow(<String>[
            l10n.animalName,
            l10n.animalSpecies,
            l10n.animalBreed,
            l10n.animalSex,
            l10n.animalStatus,
            l10n.animalBirthDate,
            l10n.animalDeathDate,
            l10n.animalColor,
            l10n.animalRegistrationNo,
            l10n.animalRegistry,
            l10n.animalMicrochip,
            l10n.animalDam,
            l10n.animalSire,
            l10n.csvColBreedingStock,
            l10n.animalNotes,
          ]);
      expect(csv, header);
      expect(header.split(','), hasLength(15));
    });

    test('a sheet in another language has that language in its headings', () async {
      // The bug this replaces: `herdCsv` wrote 'Name', 'Sex', 'Breeding stock'
      // and `animal.status.name` into the file, so a French breeder who exported
      // her herd got an English spreadsheet with `active` in a column. The
      // heading now comes from the same `.arb` the screen does.
      final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
      final csv = herdCsv(<Animal>[_animal('a-1', 'نالة')], arabic);

      expect(csv, contains(arabic.animalBreed));
      expect(csv, contains(arabic.animalStatus));
      expect(csv, contains(arabic.statusActive));
      expect(csv, contains(arabic.csvColYes));
      expect(csv, isNot(contains('Breeding stock')));
      expect(csv, isNot(contains('active')));
    });
  });

  group('the litters sheet', () {
    test('counts the puppies the ledger already registered', () {
      final animals = <Animal>[
        _animal('a-1', 'Nala'),
        Animal(
          id: 'p-1',
          name: 'Spring 1',
          species: 'dog',
          sex: Sex.unknown,
          status: AnimalStatus.active,
          litterId: 'l-1',
          createdAt: 0,
          updatedAt: 0,
        ),
        Animal(
          id: 'p-2',
          name: 'Spring 2',
          species: 'dog',
          sex: Sex.unknown,
          status: AnimalStatus.active,
          litterId: 'l-1',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];
      final litter = Litter(
        id: 'l-1',
        name: 'Spring',
        damId: 'a-1',
        whelpingDate: DateTime(2026, 4, 2).millisecondsSinceEpoch,
        createdAt: 0,
        updatedAt: 0,
      );

      final row = littersCsv(<Litter>[litter], animals, l10n).split('\r\n')[1];
      expect(row, startsWith('Spring,Nala,,'));
      expect(row, contains(',2,'));
    });
  });

  group('the vaccinations sheet', () {
    test('names the animal and writes both dates', () {
      final animals = <Animal>[_animal('a-1', 'Nala')];
      final dose = Vaccination(
        id: 'v-1',
        animalId: 'a-1',
        vaccineName: 'Rabies',
        dateAdministered: DateTime(2026, 1, 5).millisecondsSinceEpoch,
        nextDueDate: DateTime(2027, 1, 5).millisecondsSinceEpoch,
        batchNumber: 'B-77',
        createdAt: 0,
        updatedAt: 0,
      );

      final row = vaccinationsCsv(
        <Vaccination>[dose],
        animals,
        l10n,
      ).split('\r\n')[1];
      expect(row, startsWith('Nala,Rabies,2026-01-05,2027-01-05,'));
      expect(row, contains('B-77'));
    });

    test('a dose whose animal is gone keeps its row, unnamed', () {
      final dose = Vaccination(
        id: 'v-1',
        animalId: 'a-gone',
        vaccineName: 'Rabies',
        dateAdministered: DateTime(2026, 1, 5).millisecondsSinceEpoch,
        createdAt: 0,
        updatedAt: 0,
      );

      // The dose is still a fact about this phone; dropping it would make the
      // file disagree with the ledger about how many doses were given.
      expect(
        vaccinationsCsv(
          <Vaccination>[dose],
          const <Animal>[],
          l10n,
        ).split('\r\n')[1],
        startsWith(',Rabies,2026-01-05,,,,'),
      );
    });
  });

  group('the handovers sheet', () {
    test('names the buyer and writes the price with a dot', () {
      final animals = <Animal>[_animal('a-1', 'Nala')];
      final buyer = Buyer(
        id: 'b-1',
        name: 'Zoé Martin',
        countryCode: 'FR',
        createdAt: 0,
        updatedAt: 0,
      );
      final placement = Placement(
        id: 'pl-1',
        animalId: 'a-1',
        buyerId: 'b-1',
        placedDate: DateTime(2026, 2, 14).millisecondsSinceEpoch,
        price: 2500.5,
        currency: 'EUR',
        createdAt: 0,
        updatedAt: 0,
      );

      final row = placementsCsv(
        <Placement>[placement],
        animals,
        <Buyer>[buyer],
        l10n,
      ).split('\r\n')[1];
      expect(row, startsWith('Nala,Zoé Martin,FR,2026-02-14,2500.5,EUR,'));
    });

    test('a handover whose buyer was deleted writes a blank name', () {
      final animals = <Animal>[_animal('a-1', 'Nala')];
      final placement = Placement(
        id: 'pl-1',
        animalId: 'a-1',
        buyerId: 'b-gone',
        createdAt: 0,
        updatedAt: 0,
      );

      // The sale is the breeder's record; the name belonged to the buyer.
      expect(
        placementsCsv(
          <Placement>[placement],
          animals,
          const <Buyer>[],
          l10n,
        ).split('\r\n')[1],
        startsWith('Nala,,,,,,'),
      );
    });
  });
}
