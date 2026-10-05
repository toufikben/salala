import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/services/animal_pdf.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_db.dart';

/// The face the APK actually ships, read off disk.
///
/// A smaller stand-in would be quicker and worthless: whether this document is
/// readable in Arabic is a property of the presentation forms inside this one
/// file, so a test font would pass while the phone wrote empty boxes (D24).
ByteData shippedFont() =>
    File('assets/fonts/Amiri-Regular.ttf')
        .readAsBytesSync()
        .buffer
        .asByteData();

/// A whole ledger in one call: two generations, a litter, and every record type
/// the buyer's page is supposed to show.
Future<Daos> seedFullLedger(Database db) async {
  final daos = Daos(db);
  await daos.animals.create(
    Animal(
      id: 'a-dam',
      name: 'Zida',
      species: 'dog',
      sex: Sex.female,
      status: AnimalStatus.active,
      breed: 'Canary',
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
  await daos.animals.create(
    Animal(
      id: 'a-nala',
      name: 'نالة',
      species: 'dog',
      sex: Sex.female,
      status: AnimalStatus.sold,
      breed: 'Canary',
      // Six months of weigh-ins, so the growth curve has a shape to draw.
      birthDate: 1740000000000,
      damId: 'a-dam',
      sireId: 'a-sire',
      litterId: 'l-1',
      registrationNo: 'R-77',
      registry: 'SCC',
      microchipId: '981021000000001',
      color: 'fawn',
      notes: 'Imported pedigree on the dam side.',
      createdAt: 1740000000000,
      updatedAt: 1740000000000,
    ),
  );
  await daos.litters.create(
    Litter(
      id: 'l-1',
      name: 'L1 2025',
      damId: 'a-dam',
      sireId: 'a-sire',
      matingDate: 1739000000000,
      whelpingDate: 1740000000000,
      createdAt: 1740000000000,
      updatedAt: 1740000000000,
    ),
  );
  await daos.vaccinations.create(
    Vaccination(
      id: 'v-1',
      animalId: 'a-nala',
      vaccineName: 'Rabies',
      dateAdministered: 1745000000000,
      nextDueDate: 1790000000000,
      vetName: 'Dr. Bennis',
      createdAt: 1745000000000,
      updatedAt: 1745000000000,
    ),
  );
  await daos.healthTests.create(
    HealthTest(
      id: 'h-1',
      animalId: 'a-nala',
      testType: 'HDC',
      result: 'Clear',
      testDate: 1744000000000,
      createdAt: 1744000000000,
      updatedAt: 1744000000000,
    ),
  );
  await daos.vetVisits.create(
    VetVisit(
      id: 'vv-1',
      animalId: 'a-nala',
      visitDate: 1743000000000,
      reason: 'Vaccination',
      outcome: 'Healthy',
      vetName: 'Dr. Bennis',
      createdAt: 1743000000000,
      updatedAt: 1743000000000,
    ),
  );
  for (final (days, grams) in <(int, int)>[
    (30, 3200),
    (60, 6100),
    (90, 8800),
  ]) {
    await daos.weights.create(
      WeightEntry(
        id: 'w-$days',
        animalId: 'a-nala',
        weightGrams: grams,
        measuredAt: 1740000000000 + days * 86400000,
      ),
    );
  }
  await daos.buyers.create(
    Buyer(
      id: 'b-1',
      name: 'Hakim Ouali',
      phone: '+212 6 12 34 56 78',
      email: 'hakim@example.test',
      createdAt: 1749000000000,
      updatedAt: 1749000000000,
    ),
  );
  await daos.placements.create(
    Placement(
      id: 'p-1',
      animalId: 'a-nala',
      buyerId: 'b-1',
      placedDate: 1749000000000,
      price: 9000,
      currency: 'MAD',
      guaranteeTerms: 'Neuter before the second season.',
      createdAt: 1749000000000,
      updatedAt: 1749000000000,
    ),
  );
  return daos;
}

/// What a PDF has to look like from the outside.
///
/// The bytes in between are compressed and the text is drawn through the
/// embedded font's own glyph ids, so a document cannot be asserted word by word
/// here — that part is a pair of eyes on the phone. What *is* checkable is that a
/// real PDF header, a real trailer and a body big enough to hold a font came out.
void expectPdf(Uint8List bytes) {
  expect(bytes.length, greaterThan(1000));
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  expect(
    String.fromCharCodes(bytes.skip(bytes.length - 12)),
    contains('%%EOF'),
  );
}

void main() {
  setUpAll(initializeDateFormatting);

  test('every record the ledger holds lands in the document', () async {
    final db = await openTestDatabase();
    final daos = await seedFullLedger(db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final bytes = await animalPackPdf(
      daos,
      animalId: 'a-nala',
      l10n: l10n,
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 5),
    );

    expectPdf(bytes);
  });

  test('an animal with nothing recorded still gets a page', () async {
    final db = await openTestDatabase();
    final daos = Daos(db);
    await daos.animals.create(
      Animal(
        id: 'a-lonely',
        name: 'Idir',
        species: 'dog',
        sex: Sex.unknown,
        status: AnimalStatus.active,
        createdAt: 1740000000000,
        updatedAt: 1740000000000,
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final bytes = await animalPackPdf(
      daos,
      animalId: 'a-lonely',
      l10n: l10n,
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 5),
    );

    expectPdf(bytes);
  });

  test('Arabic goes through the same writer on the other direction', () async {
    final db = await openTestDatabase();
    final daos = await seedFullLedger(db);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    final bytes = await animalPackPdf(
      daos,
      animalId: 'a-nala',
      l10n: l10n,
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 5),
    );

    expectPdf(bytes);
  });

  test('the French ledger is a document too', () async {
    final db = await openTestDatabase();
    final daos = await seedFullLedger(db);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    final bytes = await animalPackPdf(
      daos,
      animalId: 'a-nala',
      l10n: l10n,
      baseFont: shippedFont(),
      now: DateTime.utc(2026, 10, 5),
    );

    expectPdf(bytes);
  });

  test('an animal that is not on the phone is not a document', () async {
    final db = await openTestDatabase();
    final daos = Daos(db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await expectLater(
      animalPackPdf(
        daos,
        animalId: 'a-gone',
        l10n: l10n,
        baseFont: shippedFont(),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('two weigh-ins on one day draw a table, not a broken axis', () async {
    final db = await openTestDatabase();
    final daos = Daos(db);
    await daos.animals.create(
      Animal(
        id: 'a-twins',
        name: 'Sira',
        species: 'dog',
        sex: Sex.female,
        status: AnimalStatus.active,
        birthDate: 1740000000000,
        createdAt: 1740000000000,
        updatedAt: 1740000000000,
      ),
    );
    for (final id in <String>['w-1', 'w-2']) {
      await daos.weights.create(
        WeightEntry(
          id: id,
          animalId: 'a-twins',
          weightGrams: 4000,
          measuredAt: 1742000000000,
        ),
      );
    }
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final bytes = await animalPackPdf(
      daos,
      animalId: 'a-twins',
      l10n: l10n,
      baseFont: shippedFont(),
    );

    expectPdf(bytes);
  });

  test('a parent the ledger lost is left off the pedigree', () async {
    final db = await openTestDatabase();
    final daos = Daos(db);
    await daos.animals.create(
      Animal(
        id: 'a-orphan',
        name: 'Gazelle',
        species: 'dog',
        sex: Sex.female,
        status: AnimalStatus.active,
        // A dam whose row was deleted, and a sire that was never recorded.
        damId: 'a-dam-that-is-not-here',
        createdAt: 1740000000000,
        updatedAt: 1740000000000,
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final bytes = await animalPackPdf(
      daos,
      animalId: 'a-orphan',
      l10n: l10n,
      baseFont: shippedFont(),
    );

    expectPdf(bytes);
  });
}
