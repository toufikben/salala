import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/schema.dart';
import 'package:salala/services/data_pack.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_db.dart';

/// Every table gets rows here, and the numbers are pinned in a test below, so
/// adding a tenth table to [dataTables] turns this file red until someone
/// decides what the pack should do with it.
Future<void> seed(Database db) async {
  await db.insert('animals', <String, Object?>{
    'id': 'a-dam',
    'name': 'Zida',
    'species': 'dog',
    'breed': 'Canary',
    'sex': 'female',
    'birth_date': 1700000000000,
    'is_breeding_stock': 1,
    'notes': 'Imported dam',
    'created_at': 1700000000000,
    'updated_at': 1700000001000,
  });
  await db.insert('litters', <String, Object?>{
    'id': 'l-1',
    'name': 'L1 2026',
    'dam_id': 'a-dam',
    'whelping_date': 1730000000000,
    'created_at': 1730000000000,
    'updated_at': 1730000000000,
  });
  // The pup names the litter while the litter names its dam, so restoring the
  // animals table before the litters table breaks a foreign key. That cycle is
  // why [restorePack] defers its checks, and this row is the proof.
  await db.insert('animals', <String, Object?>{
    'id': 'a-pup',
    'name': 'Nala',
    'species': 'dog',
    'sex': 'female',
    'litter_id': 'l-1',
    'dam_id': 'a-dam',
    'registration_no': 'R-77',
    'created_at': 1730000001000,
    'updated_at': 1730000001000,
  });
  await db.insert('vaccinations', <String, Object?>{
    'id': 'v-1',
    'animal_id': 'a-pup',
    'vaccine_name': 'Rabies',
    'date_administered': 1740000000000,
    'next_due_date': 1790000000000,
    'created_at': 1740000000000,
    'updated_at': 1740000000000,
  });
  await db.insert('vaccinations', <String, Object?>{
    'id': 'v-2',
    'animal_id': 'a-dam',
    'vaccine_name': 'Distemper',
    'date_administered': 1700000000000,
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
  });
  await db.insert('health_tests', <String, Object?>{
    'id': 'h-1',
    'animal_id': 'a-dam',
    'test_type': 'OFA hips',
    'result': 'Good',
    'test_date': 1710000000000,
    'certificate_no': 'OF-44',
    'created_at': 1710000000000,
    'updated_at': 1710000000000,
  });
  await db.insert('weight_entries', <String, Object?>{
    'id': 'w-1',
    'animal_id': 'a-pup',
    'weight_grams': 430,
    'measured_at': 1731000000000,
  });
  await db.insert('weight_entries', <String, Object?>{
    'id': 'w-2',
    'animal_id': 'a-pup',
    'weight_grams': 4200,
    'measured_at': 1740000000000,
    'note': 'Before the first vaccine',
  });
  await db.insert('vet_visits', <String, Object?>{
    'id': 't-1',
    'animal_id': 'a-pup',
    'visit_date': 1740000000000,
    'clinic_name': 'Clinic Nord',
    'cost': 250.5,
    'currency': 'DZD',
    'created_at': 1740000000000,
    'updated_at': 1740000000000,
  });
  await db.insert('symptoms', <String, Object?>{
    'id': 's-1',
    'animal_id': 'a-pup',
    'label': 'Loose stool',
    'severity': 'moderate',
    'observed_at': 1740500000000,
    'ongoing': 1,
    'note': 'Started after the change of food',
    'created_at': 1740500000000,
    'updated_at': 1740500000000,
  });
  await db.insert('symptoms', <String, Object?>{
    'id': 's-2',
    'animal_id': 'a-dam',
    'label': 'Limping',
    'severity': 'severe',
    'observed_at': 1710000000000,
    'ongoing': 0,
    'created_at': 1710000000000,
    'updated_at': 1712000000000,
  });
  await db.insert('buyers', <String, Object?>{
    'id': 'b-1',
    'name': 'Sofia',
    'phone': '+213 555 01',
    'country_code': 'DZ',
    'created_at': 1750000000000,
    'updated_at': 1750000000000,
  });
  await db.insert('placements', <String, Object?>{
    'id': 'p-1',
    'animal_id': 'a-pup',
    'buyer_id': 'b-1',
    'placed_date': 1750000000000,
    'price': 120000,
    'currency': 'DZD',
    'guarantee_terms': 'Neuter clause',
    'created_at': 1750000000000,
    'updated_at': 1750000000000,
  });
  await db.insert('user_settings', <String, Object?>{
    'key': 'language_code',
    'value': 'ar',
    'updated_at': 1750000000000,
  });
}

/// Every row of every table, in insert order, as one comparable string.
Future<String> fingerprint(Database db) async {
  final dump = <String, Object?>{
    for (final table in dataTables)
      table: await db.query(table, orderBy: 'rowid'),
  };
  return jsonEncode(dump);
}

Future<PackRows> packOf(Database db) async =>
    parsePack(encodePack(await packFrom(db)));

/// The pack's rows, typed and copied.
///
/// Copied, not viewed: a row list that came out of `db.query` is read-only, so
/// a test that wants to break a pack has to build its own mutable rows first.
Map<String, List<Map<String, Object?>>> tableRows(Map<String, Object?> pack) =>
    (pack['rows']! as Map<String, Object?>).map(
      (table, rows) => MapEntry(table, [
        for (final row in rows! as List) Map<String, Object?>.from(row as Map),
      ]),
    );

void main() {
  group('exporting', () {
    test('the pack carries every table the schema declares', () async {
      final db = await openTestDatabase();
      await seed(db);

      final pack = await packFrom(db, exportedAtMs: 1760000000000);

      expect(pack['format'], packFormat);
      expect(pack['formatVersion'], packFormatVersion);
      expect(pack['schemaVersion'], schemaVersion);
      expect(pack['exportedAt'], 1760000000000);
      expect(tableRows(pack).keys.toList(), dataTables);
      expect(tableRows(pack)['animals'], hasLength(2));
      expect(tableRows(pack)['user_settings'], hasLength(1));
    });

    test('counts reach the screen before anything is written', () async {
      final db = await openTestDatabase();
      await seed(db);

      final pack = await packOf(db);

      expect(pack.countOf('animals'), 2);
      expect(pack.countOf('weight_entries'), 2);
      expect(pack.countOf('symptoms'), 2);
      expect(pack.countOf('secrets'), 0);
      expect(pack.totalRows, 14);
    });
  });

  group('round trip', () {
    test(
      'a pack restores an empty database to the original, rows and all',
      () async {
        final source = await openTestDatabase();
        await seed(source);
        final text = encodePack(await packFrom(source));

        final target = await openTestDatabase();
        await restorePack(target, parsePack(text));

        expect(await fingerprint(target), await fingerprint(source));
      },
    );

    test(
      'a restore replaces the ledger that was already on the phone',
      () async {
        final source = await openTestDatabase();
        await seed(source);
        final pack = await packOf(source);

        final target = await openTestDatabase();
        await target.insert('animals', <String, Object?>{
          'id': 'other',
          'name': 'Someone else',
          'species': 'cat',
          'created_at': 1,
          'updated_at': 1,
        });

        await restorePack(target, pack);

        expect(await fingerprint(target), await fingerprint(source));
        final rows = await target.query('animals', where: "id = 'other'");
        expect(rows, isEmpty);
      },
    );

    test('an empty pack empties the database', () async {
      final db = await openTestDatabase();
      await seed(db);

      await restorePack(
        db,
        parsePack(
          encodePack(<String, Object?>{
            'format': packFormat,
            'formatVersion': packFormatVersion,
            'schemaVersion': schemaVersion,
            'rows': <String, Object?>{for (final t in dataTables) t: []},
          }),
        ),
      );

      for (final table in dataTables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
    });

    test('nulls, integers and decimals survive the JSON', () async {
      final source = await openTestDatabase();
      await seed(source);
      final target = await openTestDatabase();
      await restorePack(target, await packOf(source));

      final visit = (await target.query('vet_visits')).single;
      expect(visit['cost'], 250.5);
      expect(visit['clinic_name'], 'Clinic Nord');
      expect((await target.query('animals')).first['death_date'], isNull);
      final weight = await target.query(
        'weight_entries',
        where: 'id = ?',
        whereArgs: <Object?>['w-1'],
      );
      expect(weight.single['weight_grams'], 430);
      expect(weight.single['note'], isNull);
    });
  });

  group('reading a file', () {
    test('a file that is not JSON is not a pack', () {
      expect(
        () => parsePack('not json at all'),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.unreadable,
          ),
        ),
      );
      expect(
        () => parsePack('[1, 2, 3]'),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.unreadable,
          ),
        ),
      );
    });

    test('JSON without the pack tag is not a pack', () {
      expect(
        () => parsePack('{"format":"other","rows":{}}'),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.notAPack,
          ),
        ),
      );
      expect(
        () => parsePack('{"format":"$packFormat"}'),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.notAPack,
          ),
        ),
      );
    });

    test('a stamp that is not a number is named, not thrown on', () async {
      final db = await openTestDatabase();
      await seed(db);
      // Every table is present and genuine, so the only thing wrong with the file
      // is the date the restore dialog reads out loud. Reading that key with
      // `as int?` threw a TypeError out of `parsePack`, which is the one thing
      // this file is careful never to do: hand the breeder a named reason rather
      // than a crash, for a file someone re-typed in a text editor.
      final Object? whole = jsonDecode(encodePack(await packFrom(db)));
      (whole! as Map<String, Object?>)['exportedAt'] = 'last week';

      expect(
        () => parsePack(jsonEncode(whole)),
        throwsA(
          isA<PackReject>()
              .having((e) => e.problem, 'problem', PackProblem.notAPack)
              .having((e) => e.detail, 'detail', 'exportedAt'),
        ),
      );
    });

    test('a stamp written as a decimal is the same instant', () async {
      final db = await openTestDatabase();
      await seed(db);
      // JSON has one number type, and a tool that re-wrote the whole number as
      // `1759000000000.0` means that exact millisecond — not a damaged file.
      final Object? whole = jsonDecode(encodePack(await packFrom(db)));
      (whole! as Map<String, Object?>)['exportedAt'] = 1759000000000.0;

      expect(parsePack(jsonEncode(whole)).exportedAtMs, 1759000000000);
    });

    test('a pack from a newer app is refused instead of half-read', () async {
      final db = await openTestDatabase();
      await seed(db);
      final pack = await packFrom(db);

      expect(
        () => parsePack(
          encodePack(<String, Object?>{
            ...pack,
            'formatVersion': packFormatVersion + 1,
          }),
        ),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.fromTheFuture,
          ),
        ),
      );
      expect(
        () => parsePack(
          encodePack(<String, Object?>{
            ...pack,
            'schemaVersion': schemaVersion + 3,
          }),
        ),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.fromTheFuture,
          ),
        ),
      );
    });

    test('a truncated pack is refused, not restored partially', () async {
      final db = await openTestDatabase();
      await seed(db);
      final pack = await packFrom(db);

      final rows = tableRows(pack)..remove('vaccinations');

      expect(
        () => parsePack(encodePack(<String, Object?>{...pack, 'rows': rows})),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.missingTable,
          ),
        ),
      );
    });

    test('a pack older than a table forgives that table alone', () async {
      final db = await openTestDatabase();
      await seed(db);
      // `symptoms` is the first table this app grew rather than shipped with, so
      // a version 1 backup never held it. The rule that pins that is private to
      // the reader, so the test asks the reader itself: a file stamped with the
      // current schema and missing a table is damaged (the test above), while the
      // same file stamped one schema back is an honest backup of a ledger that
      // had no symptoms in it yet. Restoring it fills every table it did carry
      // and leaves the newer one empty rather than refusing the breeder's only
      // backup.
      final pack = await packFrom(db);
      final rows = tableRows(pack)..remove('symptoms');

      final parsed = parsePack(
        encodePack(<String, Object?>{
          ...pack,
          'schemaVersion': 1,
          'rows': rows,
        }),
      );

      expect(parsed.countOf('symptoms'), 0);
      expect(parsed.countOf('animals'), 2);

      final target = await openTestDatabase();
      await restorePack(target, parsed);
      expect(await target.query('symptoms'), isEmpty);
      expect(await target.query('animals'), hasLength(2));
    });

    test('a table this app does not have stops the restore', () async {
      final db = await openTestDatabase();
      await seed(db);
      final pack = await packFrom(db);

      final rows = tableRows(pack)
        ..['secrets'] = <Map<String, Object?>>[
          <String, Object?>{'key': 'pin', 'value': '1234'},
        ];

      expect(
        () => parsePack(encodePack(<String, Object?>{...pack, 'rows': rows})),
        throwsA(
          isA<PackReject>()
              .having((e) => e.problem, 'problem', PackProblem.unknownTable)
              .having((e) => e.detail, 'detail', 'secrets'),
        ),
      );
    });
  });

  group('a restore that cannot be honoured', () {
    test('changes nothing on the phone', () async {
      final db = await openTestDatabase();
      await seed(db);
      final before = await fingerprint(db);

      final source = await openTestDatabase();
      await seed(source);
      final pack = await packFrom(source);
      // The dam goes missing, so her litter and two records point at nothing.
      final broken = tableRows(pack)
        ..['animals']!.removeWhere((row) => row['id'] == 'a-dam');

      await expectLater(
        restorePack(db, parsePack(encodePack({...pack, 'rows': broken}))),
        throwsA(
          isA<PackReject>().having(
            (e) => e.problem,
            'problem',
            PackProblem.danglingReference,
          ),
        ),
      );

      // Querying after the refusal is the half of this test that used to hang:
      // a commit rejected on a deferred foreign key leaves the handle inside the
      // transaction, and the next call waits for a lock nobody releases.
      expect(await fingerprint(db), before);
    });

    test('a column this app has not written refuses the pack', () async {
      final db = await openTestDatabase();
      await seed(db);

      final pack = <String, Object?>{
        'format': packFormat,
        'formatVersion': packFormatVersion,
        'schemaVersion': schemaVersion,
        'rows': <String, Object?>{
          for (final t in dataTables) t: <Object?>[],
          'animals': <Object?>[
            <String, Object?>{
              'id': 'a1',
              'name': 'Zida',
              'species': 'dog',
              'weather_column': 1,
              'created_at': 1,
              'updated_at': 1,
            },
          ],
        },
      };

      await expectLater(
        restorePack(db, parsePack(encodePack(pack))),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('animals'), hasLength(2));
    });
  });
}
