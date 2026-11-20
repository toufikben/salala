import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/data/db/schema.dart' show schemaVersion;
import 'package:companion/services/data_pack.dart';
import 'package:companion/services/pack_archive.dart';

import '../helpers/fake_photo_files.dart';
import '../helpers/test_db.dart';

/// The container the backup travels in.
///
/// The pack's own rules are `data_pack_test.dart`'s; what is proved here is the
/// ZIP around it — that the ledger and the pictures survive the round trip, that
/// a plain JSON pack still opens, and that an entry which is a path rather than
/// a name can never be written to the phone.
void main() {
  Uint8List utf8Bytes(String text) => Uint8List.fromList(utf8.encode(text));

  test('the ledger and its pictures come back out of one file', () {
    final bytes = encodePackArchive(
      '{"format":"salala-pack"}',
      <String, List<int>>{
        'atlas/1759000000000-4.jpg': <int>[1, 2, 3],
        'zida/1759000000001-9.png': <int>[9, 8],
      },
    );

    // The bytes decide the shape, not the file name: a breeder may rename this.
    expect(isZipBytes(bytes), isTrue);

    final read = decodePackArchive(bytes);
    expect(read.json, '{"format":"salala-pack"}');
    expect(read.photos, <String, List<int>>{
      'atlas/1759000000000-4.jpg': <int>[1, 2, 3],
      'zida/1759000000001-9.png': <int>[9, 8],
    });
  });

  test('a plain JSON pack is not mistaken for an archive', () {
    expect(isZipBytes(utf8Bytes('{"format":"salala-pack"}')), isFalse);
    expect(isZipBytes(<int>[]), isFalse);
  });

  test('a file that is not an archive is refused, not read half way', () {
    // Half of a real pack: the local header of the first entry, which is exactly
    // what a transfer cut off by a flat battery leaves on the phone. The decoder
    // answers an empty archive rather than throwing, so it is this app's own
    // check for `pack.json` that turns half a file into a sentence instead of a
    // ledger with no rows in it.
    final whole = encodePackArchive(
      '{"format":"salala-pack"}',
      <String, List<int>>{
        'atlas/a.jpg': <int>[1, 2, 3],
      },
    );
    final half = whole.sublist(0, whole.length ~/ 2);

    expect(
      () => decodePackArchive(half),
      throwsA(
        isA<PackReject>().having(
          (r) => r.problem,
          'problem',
          PackProblem.notAPack,
        ),
      ),
    );
  });

  test('a pack.json that is not text is unreadable, not an empty ledger', () {
    final archive = Archive()
      ..addFile(ArchiveFile(packEntryName, 2, <int>[0xFF, 0xFE]));

    expect(
      () => decodePackArchive(ZipEncoder().encode(archive)),
      throwsA(
        isA<PackReject>().having(
          (r) => r.problem,
          'problem',
          PackProblem.unreadable,
        ),
      ),
    );
  });

  test('an archive with no pack.json is not a pack', () {
    final archive = Archive()
      ..addFile(ArchiveFile('photos/atlas/a.jpg', 1, <int>[1]));
    final bytes = ZipEncoder().encode(archive);

    expect(
      () => decodePackArchive(bytes),
      throwsA(
        isA<PackReject>().having(
          (r) => r.problem,
          'problem',
          PackProblem.notAPack,
        ),
      ),
    );
  });

  test('an entry that is a path rather than a name is never carried', () {
    // What a hostile or broken file looks like: a picture entry that climbs out
    // of the folder this app owns. Reading it must not even offer it back.
    final archive = Archive()
      ..addFile(ArchiveFile(packEntryName, 2, <int>[123, 125]))
      ..addFile(ArchiveFile('photos/../../evil.jpg', 1, <int>[1]))
      ..addFile(ArchiveFile('photos/atlas/../../evil.jpg', 1, <int>[1]))
      ..addFile(ArchiveFile('photos/atlas', 1, <int>[1]))
      ..addFile(ArchiveFile('photos/atlas/a/b.jpg', 1, <int>[1]))
      ..addFile(ArchiveFile('other/notes.txt', 2, <int>[65, 66]));

    final read = decodePackArchive(ZipEncoder().encode(archive));

    expect(read.photos, isEmpty);
  });

  test('a name with a space or a dot is a name, and travels', () {
    final bytes = encodePackArchive('{}', <String, List<int>>{
      'atlas/a photo-2.jpg': <int>[4],
    });

    expect(decodePackArchive(bytes).photos.keys, <String>[
      'atlas/a photo-2.jpg',
    ]);
  });

  test('the export carries the bytes of every picture the rows name', () async {
    final db = await openTestDatabase();
    await db.insert('animals', <String, Object?>{
      'id': 'atlas',
      'name': 'Atlas',
      'species': 'dog',
      'sex': 'male',
      'created_at': 1759000000000,
      'updated_at': 1759000000000,
    });
    await db.insert('photos', <String, Object?>{
      'id': 'p-1',
      'animal_id': 'atlas',
      'file_name': '1759000000000-4.jpg',
      'created_at': 1759000000000,
    });
    // A row whose file is gone is still a row: the ledger exports it, and the
    // archive simply has no picture for it.
    await db.insert('photos', <String, Object?>{
      'id': 'p-2',
      'animal_id': 'atlas',
      'file_name': '1759000000001-9.jpg',
      'created_at': 1759000000001,
    });

    final files = FakePhotoFiles(
      bytes: <String, List<int>>{
        'atlas/1759000000000-4.jpg': <int>[7, 7, 7],
      },
    );

    final read = decodePackArchive(await buildPackArchive(db, files));

    final rows = parsePack(read.json).tables['photos']!;
    expect(rows, hasLength(2));
    expect(read.photos, <String, List<int>>{
      'atlas/1759000000000-4.jpg': <int>[7, 7, 7],
    });
  });

  test(
    'a picture row from the pack and one from this phone both survive',
    () async {
      final db = await openTestDatabase();
      await db.insert('animals', <String, Object?>{
        'id': 'atlas',
        'name': 'Atlas',
        'species': 'dog',
        'sex': 'male',
        'created_at': 1759000000000,
        'updated_at': 1759000000000,
      });
      // This phone's own picture, which the incoming pack does not name.
      await db.insert('photos', <String, Object?>{
        'id': 'p-own',
        'animal_id': 'atlas',
        'file_name': 'own.jpg',
        'created_at': 1759000000000,
      });

      final incoming = <String, Object?>{
        'format': packFormat,
        'formatVersion': packFormatVersion,
        'schemaVersion': schemaVersion,
        'exportedAt': 1759000000000,
        'rows': <String, Object?>{
          for (final table in <String>[
            'animals',
            'litters',
            'vaccinations',
            'health_tests',
            'weight_entries',
            'vet_visits',
            'symptoms',
            'buyers',
            'placements',
            'user_settings',
          ])
            table: <Object?>[],
          'photos': <Object?>[
            <String, Object?>{
              'id': 'p-in',
              'animal_id': 'atlas',
              'file_name': 'in.jpg',
              'created_at': 1759000000000,
            },
          ],
        },
      };
      (incoming['rows']! as Map<String, Object?>)['animals'] = <Object?>[
        <String, Object?>{
          'id': 'atlas',
          'name': 'Atlas',
          'species': 'dog',
          'sex': 'male',
          'is_breeding_stock': 0,
          'status': 'active',
          'created_at': 1759000000000,
          'updated_at': 1759000000000,
        },
      ];

      final kept = await restorePack(db, parsePack(jsonEncode(incoming)));

      // Both lists are kept. The pack's row names the file the archive wrote
      // beside it; this phone's row names bytes nothing can recreate. A restore
      // that dropped either would hide a picture that is still on the disk.
      expect(kept.map((photo) => photo.fileName).toList()..sort(), <String>[
        'in.jpg',
        'own.jpg',
      ]);
      final rows = await db.query('photos', orderBy: 'file_name');
      expect(rows.map((row) => row['file_name']), <String>[
        'in.jpg',
        'own.jpg',
      ]);
    },
  );

  test('a pack written before pictures keeps the phone\'s own rows', () async {
    final db = await openTestDatabase();
    await db.insert('animals', <String, Object?>{
      'id': 'atlas',
      'name': 'Atlas',
      'species': 'dog',
      'sex': 'male',
      'created_at': 1759000000000,
      'updated_at': 1759000000000,
    });
    await db.insert('photos', <String, Object?>{
      'id': 'p-own',
      'animal_id': 'atlas',
      'file_name': 'own.jpg',
      'created_at': 1759000000000,
    });

    final legacy = <String, Object?>{
      'format': packFormat,
      'formatVersion': packFormatVersion,
      'schemaVersion': schemaVersion,
      'rows': <String, Object?>{
        for (final table in <String>[
          'animals',
          'litters',
          'vaccinations',
          'health_tests',
          'weight_entries',
          'vet_visits',
          'symptoms',
          'buyers',
          'placements',
          'user_settings',
        ])
          table: <Object?>[],
      },
    };
    (legacy['rows']! as Map<String, Object?>)['animals'] = <Object?>[
      <String, Object?>{
        'id': 'atlas',
        'name': 'Atlas',
        'species': 'dog',
        'sex': 'male',
        'is_breeding_stock': 0,
        'status': 'active',
        'created_at': 1759000000000,
        'updated_at': 1759000000000,
      },
    ];

    final kept = await restorePack(db, parsePack(jsonEncode(legacy)));

    expect(kept.map((photo) => photo.fileName), <String>['own.jpg']);
  });
}
