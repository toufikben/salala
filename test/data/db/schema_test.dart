import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/app_database.dart';
import 'package:salala/data/db/schema.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/test_db.dart';

Future<int> _count(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
  return rows.first['c']! as int;
}

final RegExp _whitespace = RegExp(r'\s+');

void main() {
  group('the current schema', () {
    test('the table list a pack carries matches the tables it creates', () {
      final created = <String>[
        for (final statement in createStatements)
          if (statement.trimLeft().startsWith('CREATE TABLE'))
            statement.trimLeft().split(_whitespace)[2],
      ];

      // A table missing from both lists is a table no export carries and no
      // restore writes back, which is the kind of data loss no screen shows.
      // `photos` is in the second list on purpose: its rows are pointers into a
      // folder the pack does not travel with, so it must *not* be in `dataTables`.
      final listed = <String>[...dataTables, ...fileBackedTables];
      expect(listed.toSet(), created.toSet());
      expect(listed, hasLength(created.length));
    });

    test('creates every table the app reads', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );
      final tables = rows.map((r) => r['name'] as String).toSet();

      expect(
        tables,
        containsAll(<String>[
          'animals',
          'litters',
          'vaccinations',
          'health_tests',
          'weight_entries',
          'vet_visits',
          'symptoms',
          'photos',
          'buyers',
          'placements',
          'user_settings',
        ]),
      );
    });

    test('every index the schema declares is present', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      final declared = createStatements
          .where((s) => s.trimLeft().startsWith('CREATE INDEX'))
          .length;
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
      );
      // Counted against the schema rather than a number typed here, so a new
      // index cannot be added to `createStatements` without being created.
      expect(rows.length, declared);
      expect(declared, 11);
    });

    test('user_version matches the declared schema version', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      final rows = await db.rawQuery('PRAGMA user_version');
      expect(rows.first['user_version'], schemaVersion);
    });

    test('deleting an animal cascades to its dependent records', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      await db.insert('animals', <String, Object?>{
        'id': 'a1',
        'name': 'Zida',
        'species': 'dog',
        'created_at': 1,
        'updated_at': 1,
      });
      await db.insert('vaccinations', <String, Object?>{
        'id': 'v1',
        'animal_id': 'a1',
        'vaccine_name': 'Rabies',
        'date_administered': 1,
        'created_at': 1,
        'updated_at': 1,
      });
      await db.insert('weight_entries', <String, Object?>{
        'id': 'w1',
        'animal_id': 'a1',
        'weight_grams': 4200,
        'measured_at': 1,
      });
      await db.insert('symptoms', <String, Object?>{
        'id': 's1',
        'animal_id': 'a1',
        'label': 'Cough',
        'severity': 'mild',
        'observed_at': 1,
        'ongoing': 1,
        'created_at': 1,
        'updated_at': 1,
      });

      await db.insert('photos', <String, Object?>{
        'id': 'ph1',
        'animal_id': 'a1',
        'file_name': '1-100.jpg',
        'created_at': 1,
      });

      // The two the delete dialog's copy left out until this test said so: a
      // handover recorded for this animal, and a whelping it is the dam of. One
      // of that whelping's puppies is inserted too, because what happens to *it*
      // is the part nobody would guess — the whelping row goes, the young stay in
      // the herd with their litter link cleared.
      await db.insert('placements', <String, Object?>{
        'id': 'p1',
        'animal_id': 'a1',
        'placed_date': 1,
        'price': 900.0,
        'currency': 'MAD',
        'created_at': 1,
        'updated_at': 1,
      });
      await db.insert('litters', <String, Object?>{
        'id': 'l1',
        'name': 'Zida 2026',
        'dam_id': 'a1',
        'whelping_date': 1,
        'created_at': 1,
        'updated_at': 1,
      });
      await db.insert('animals', <String, Object?>{
        'id': 'a2',
        'name': 'Zida pup',
        'species': 'dog',
        'litter_id': 'l1',
        'created_at': 1,
        'updated_at': 1,
      });

      await db.delete('animals', where: 'id = ?', whereArgs: <Object?>['a1']);

      expect(await _count(db, 'vaccinations'), 0);
      expect(await _count(db, 'weight_entries'), 0);
      expect(await _count(db, 'symptoms'), 0);
      expect(
        await _count(db, 'photos'),
        0,
        reason:
            'the rows go with the animal; the bytes are the screen above this '
            'table\'s job, and a folder the ledger no longer points at is '
            'what `deleteAll` is for',
      );
      expect(await _count(db, 'placements'), 0);
      expect(await _count(db, 'litters'), 0);
      final survivors = await db.query('animals');
      expect(survivors, hasLength(1));
      expect(survivors.single['id'], 'a2');
      expect(survivors.single['litter_id'], isNull);
    });

    test('deleting a sire clears the reference instead of the puppy', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      await db.insert('animals', <String, Object?>{
        'id': 'sire',
        'name': 'Sire',
        'species': 'dog',
        'created_at': 1,
        'updated_at': 1,
      });
      await db.insert('animals', <String, Object?>{
        'id': 'pup',
        'name': 'Pup',
        'species': 'dog',
        'sire_id': 'sire',
        'created_at': 1,
        'updated_at': 1,
      });

      await db.delete('animals', where: 'id = ?', whereArgs: <Object?>['sire']);

      final pup = await db.query('animals', where: "id = 'pup'");
      expect(pup.single['sire_id'], isNull);
    });

    test(
      'an orphan vaccination is rejected while foreign keys are on',
      () async {
        final db = await openTestDatabase();
        addTearDown(db.close);

        await expectLater(
          db.insert('vaccinations', <String, Object?>{
            'id': 'v2',
            'animal_id': 'nope',
            'vaccine_name': 'Distemper',
            'date_administered': 1,
            'created_at': 1,
            'updated_at': 1,
          }),
          throwsA(anything),
        );
      },
    );
  });

  group('migrations', () {
    test('version 2 gives an older install the symptoms table', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      // The shape a version-1 phone holds: everything this build creates, minus
      // what version 2 added. Dropping it here rather than committing a v1
      // schema file keeps the two definitions from drifting apart unnoticed —
      // the step under test has to rebuild exactly what `createStatements`
      // writes, which is what `createSymptomsTable` is for.
      await db.execute('DROP INDEX idx_symptoms_animal');
      await db.execute('DROP TABLE symptoms');
      await db.insert('animals', <String, Object?>{
        'id': 'a1',
        'name': 'Zida',
        'species': 'dog',
        'created_at': 1,
        'updated_at': 1,
      });

      await AppDatabase.runMigrations(db, 1, 2);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'symptoms'",
      );
      expect(tables, hasLength(1));
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_symptoms_animal'",
      );
      expect(indexes, hasLength(1));

      // Upgrading has to leave a usable table behind, not just a name: the animal
      // that was already on the phone still owns the sighting written after it.
      await db.insert('symptoms', <String, Object?>{
        'id': 's1',
        'animal_id': 'a1',
        'label': 'Cough',
        'severity': 'mild',
        'observed_at': 1,
        'ongoing': 1,
        'created_at': 1,
        'updated_at': 1,
      });
      expect(await _count(db, 'symptoms'), 1);
      expect(await _count(db, 'animals'), 1);

      await expectLater(
        db.insert('symptoms', <String, Object?>{
          'id': 's2',
          'animal_id': 'nobody',
          'label': 'Orphan',
          'severity': 'mild',
          'observed_at': 1,
          'ongoing': 1,
          'created_at': 1,
          'updated_at': 1,
        }),
        throwsA(anything),
      );
    });

    test('version 3 gives an older install the photos table', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      // The same trick as the step above: a version-2 phone is this schema with
      // `photos` taken away, so the migration under test has to rebuild exactly
      // what `createPhotosTable` writes rather than a hand-typed copy of it.
      await db.execute('DROP INDEX idx_photos_animal');
      await db.execute('DROP TABLE photos');
      await db.insert('animals', <String, Object?>{
        'id': 'a1',
        'name': 'Zida',
        'species': 'dog',
        'created_at': 1,
        'updated_at': 1,
      });

      await AppDatabase.runMigrations(db, 2, 3);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'photos'",
      );
      expect(tables, hasLength(1));
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_photos_animal'",
      );
      expect(indexes, hasLength(1));

      await db.insert('photos', <String, Object?>{
        'id': 'ph1',
        'animal_id': 'a1',
        'file_name': '1729000000000-20480.jpg',
        'created_at': 1,
      });
      expect(await _count(db, 'photos'), 1);

      // The upgraded table is the guarded one, not a name in the schema log: a
      // picture whose animal is not on the phone has nothing to hang on.
      await expectLater(
        db.insert('photos', <String, Object?>{
          'id': 'ph2',
          'animal_id': 'nobody',
          'file_name': 'stray.jpg',
          'created_at': 1,
        }),
        throwsA(anything),
      );
    });

    test('an unregistered target version fails loudly', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      await expectLater(
        AppDatabase.runMigrations(db, schemaVersion, schemaVersion + 1),
        throwsStateError,
      );
    });

    test('a registered step runs once per version gap', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      var ran = 0;
      AppDatabase.registerMigration(schemaVersion + 1, (target) async {
        ran++;
        await target.execute('CREATE TABLE scratch (id INTEGER PRIMARY KEY)');
      });

      await AppDatabase.runMigrations(db, schemaVersion, schemaVersion + 1);
      expect(ran, 1);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'scratch'",
      );
      expect(rows, hasLength(1));

      AppDatabase.resetMigrationsForTest();
    });
  });
}
