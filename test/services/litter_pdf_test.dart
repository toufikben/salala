import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/services/litter_pdf.dart';
import 'package:salala/services/pdf_layout.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_db.dart';

/// The face the APK actually ships, read off disk.
///
/// Same reason as the animal pack's test: whether an Arabic whelping record is
/// readable is a property of this file's presentation forms, and a test font
/// would pass while the phone wrote empty boxes (D24).
ByteData shippedFont() =>
    File('assets/fonts/Amiri-Regular.ttf')
        .readAsBytesSync()
        .buffer
        .asByteData();

void expectPdf(Uint8List bytes) {
  expect(bytes.length, greaterThan(1000));
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  expect(
    String.fromCharCodes(bytes.skip(bytes.length - 12)),
    contains('%%EOF'),
  );
}

/// One whelping, three puppies, and the records a breeder actually keeps during
/// a litter: a round of doses, weigh-ins, and one puppy that went home.
Future<Daos> seedLitter(Database db) async {
  final daos = Daos(db);
  await daos.animals.create(
    Animal(
      id: 'a-dam',
      name: 'Zida',
      species: 'dog',
      sex: Sex.female,
      status: AnimalStatus.active,
      createdAt: 1700000000000,
      updatedAt: 1700000000000,
    ),
  );
  await daos.animals.create(
    Animal(
      id: 'a-sire',
      name: 'Atlas',
      species: 'dog',
      sex: Sex.male,
      status: AnimalStatus.retired,
      createdAt: 1700000000000,
      updatedAt: 1700000000000,
    ),
  );
  // The litter row before the puppies: animals.litter_id is a real foreign key.
  await daos.litters.create(
    Litter(
      id: 'l-1',
      name: 'L1 2025',
      damId: 'a-dam',
      sireId: 'a-sire',
      matingDate: 1739000000000,
      whelpingDate: 1740000000000,
      weaningDate: 1742600000000,
      notes: 'Three puppies, one caesarean. Whelped at home.',
      createdAt: 1740000000000,
      updatedAt: 1740000000000,
    ),
  );
  for (final Animal puppy in <Animal>[
    Animal(
      id: 'a-1',
      name: 'Sirin',
      species: 'dog',
      sex: Sex.female,
      status: AnimalStatus.active,
      litterId: 'l-1',
      birthDate: 1740000000000,
      createdAt: 1740000000000,
      updatedAt: 1740000000000,
    ),
    Animal(
      id: 'a-2',
      name: 'نالة',
      species: 'dog',
      sex: Sex.female,
      status: AnimalStatus.sold,
      litterId: 'l-1',
      birthDate: 1740000000000,
      createdAt: 1740000000000,
      updatedAt: 1740000000000,
    ),
    Animal(
      id: 'a-3',
      name: 'Zuzu',
      species: 'dog',
      sex: Sex.male,
      status: AnimalStatus.active,
      litterId: 'l-1',
      birthDate: 1740000000000,
      createdAt: 1740000000000,
      updatedAt: 1740000000000,
    ),
  ]) {
    await daos.animals.create(puppy);
  }
  // A round given to two of the three: the page has to show which one was missed.
  for (final id in <String>['a-1', 'a-2']) {
    await daos.vaccinations.create(
      Vaccination(
        id: 'v-$id',
        animalId: id,
        vaccineName: 'DHPP',
        dateAdministered: 1742000000000,
        nextDueDate: id == 'a-1' ? 1744600000000 : null,
        vetName: 'Dr Hakam',
        createdAt: 1742000000000,
        updatedAt: 1742000000000,
      ),
    );
  }
  await daos.weights.create(
    WeightEntry(
      id: 'w-1',
      animalId: 'a-1',
      weightGrams: 2400,
      measuredAt: 1742000000000,
    ),
  );
  await daos.buyers.create(
    Buyer(
      id: 'b-1',
      name: 'Nadia Sabri',
      countryCode: 'MA',
      createdAt: 1750000000000,
      updatedAt: 1750000000000,
    ),
  );
  await daos.placements.create(
    Placement(
      id: 'p-1',
      animalId: 'a-2',
      buyerId: 'b-1',
      placedDate: 1743000000000,
      price: 2500,
      currency: 'MAD',
      createdAt: 1743000000000,
      updatedAt: 1743000000000,
    ),
  );
  return daos;
}

Future<AppLocalizations> messages(String language) =>
    AppLocalizations.delegate.load(Locale(language));

void main() {
  setUpAll(initializeDateFormatting);

  test(
    'a whelping with puppies, doses and one handover makes a page',
    () async {
      final db = await openTestDatabase();
      final daos = await seedLitter(db);
      final l10n = await messages('en');

      final bytes = await litterPackPdf(
        daos,
        litterId: 'l-1',
        l10n: l10n,
        baseFont: shippedFont(),
        now: DateTime.utc(2026, 10, 8),
      );

      expectPdf(bytes);
    },
  );

  test('a litter registered before any puppy still gets its record', () async {
    // The page a breeder prints on the day of the mating, to hang the expected
    // whelping date on the wall: no puppies, no doses, nobody to hand over to.
    final db = await openTestDatabase();
    final daos = Daos(db);
    await daos.animals.create(
      Animal(
        id: 'a-dam',
        name: 'Zida',
        species: 'dog',
        sex: Sex.female,
        status: AnimalStatus.active,
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
      ),
    );
    await daos.litters.create(
      Litter(
        id: 'l-empty',
        name: 'Planned',
        damId: 'a-dam',
        createdAt: 1740000000000,
        updatedAt: 1740000000000,
      ),
    );

    final bytes = await litterPackPdf(
      daos,
      litterId: 'l-empty',
      l10n: await messages('en'),
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 8),
    );

    expectPdf(bytes);
  });

  test('the Arabic whelping record is written with the shipped font', () async {
    // Direction, not just glyphs: an RTL document built as LTR is a page of
    // backwards sentences that a test over bytes cannot see failing (D24).
    final db = await openTestDatabase();
    final daos = await seedLitter(db);

    final bytes = await litterPackPdf(
      daos,
      litterId: 'l-1',
      l10n: await messages('ar'),
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 8),
    );

    expectPdf(bytes);
  });

  test(
    'an id that answers to no litter is refused, not printed as a blank page',
    () async {
      final db = await openTestDatabase();
      final daos = Daos(db);

      await expectLater(
        litterPackPdf(
          daos,
          litterId: 'l-gone',
          l10n: await messages('en'),
          baseFont: shippedFont(),
        ),
        throwsStateError,
      );
    },
  );

  test('a big litter fits the document the page count allows', () async {
    // Twelve puppies is a real whelping, and the row list is what makes the page
    // run: 40 pages is the writer's own ceiling, so a litter that reached it
    // would silently lose the rest of the record.
    final db = await openTestDatabase();
    final daos = await seedLitter(db);
    await daos.animals.create(
      Animal(
        id: 'a-dam-2',
        name: 'Ruby',
        species: 'dog',
        sex: Sex.female,
        status: AnimalStatus.active,
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
      ),
    );
    await daos.litters.create(
      Litter(
        id: 'l-big',
        name: 'L9 2025',
        damId: 'a-dam-2',
        whelpingDate: 1740000000000,
        createdAt: 1740000000000,
        updatedAt: 1740000000000,
      ),
    );
    for (var i = 0; i < 12; i++) {
      final id = 'a-big-$i';
      await daos.animals.create(
        Animal(
          id: id,
          name: 'Puppy ${String.fromCharCode(65 + i)}',
          species: 'dog',
          sex: i.isEven ? Sex.male : Sex.female,
          status: AnimalStatus.active,
          litterId: 'l-big',
          birthDate: 1740000000000,
          createdAt: 1740000000000,
          updatedAt: 1740000000000,
        ),
      );
      await daos.vaccinations.create(
        Vaccination(
          id: 'v-big-$i',
          animalId: id,
          vaccineName: 'DHPP',
          dateAdministered: 1742000000000,
          createdAt: 1742000000000,
          updatedAt: 1742000000000,
        ),
      );
    }

    final bytes = await litterPackPdf(
      daos,
      litterId: 'l-big',
      l10n: await messages('en'),
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 8),
    );

    expectPdf(bytes);
  });
}
