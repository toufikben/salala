import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/app_database.dart';
import 'package:salala/data/db/schema.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/test_db.dart';

Future<int> _count(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
  return rows.first['c']! as int;
}

void main() {
  group('schema v1', () {
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
          'buyers',
          'placements',
          'user_settings',
        ]),
      );
    });

    test('all nine indexes from the schema are present', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
      );
      expect(rows.length, 9);
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

      await db.delete('animals', where: 'id = ?', whereArgs: <Object?>['a1']);

      expect(await _count(db, 'vaccinations'), 0);
      expect(await _count(db, 'weight_entries'), 0);
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
