import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/db/schema.dart';
import '../data/models/photo.dart';

/// The whole database as one JSON document (Stage 2).
///
/// This is the honest answer to "what if I lose my phone": a file the breeder
/// can put on a USB stick, an email, or a second device, with no server holding
/// a copy of their ledger.
///
/// The pack is generic over [dataTables] rather than over the models on purpose.
/// A restore has to put back the rows the app wrote, including columns a future
/// version may add, and a format that travels table-by-table costs one line in
/// `schema.dart` per new table instead of a branch here.
///
/// Photos are **not** rows this module restores on their own. A `photos` row is
/// a file name, and the bytes are what make it worth anything: the export puts
/// the rows in the pack and the files in a ZIP beside it (`pack_archive.dart`),
/// so a restore on a second phone gets both. A pack holding the rows but no
/// bytes is still accepted — the pictures then render as the named blank this
/// app already draws for a file the phone does not have.es on the old phone, and the ledger says so per row.
/// The PDF pack is where an image belongs.
const String packFormat = 'salala-pack';

/// Bumped only when an older app can no longer read the file. Adding a table is
/// not a new version: [parsePack] accepts whatever tables it knows and a future
/// pack still carries the ones it has.
const int packFormatVersion = 1;

/// Why a file is not a pack this app can restore.
enum PackProblem {
  /// Not JSON at all, or JSON that is not an object.
  unreadable,

  /// JSON, but not a Companion pack: no format tag, or a body of the wrong shape.
  notAPack,

  /// Written by a newer format or a newer schema than this app has.
  fromTheFuture,

  /// Names a table this app does not have.
  unknownTable,

  /// Leaves out a table this app has.
  missingTable,

  /// Points a row at a record the pack does not carry.
  ///
  /// Only knowable once the rows are in place, so this one surfaces from
  /// [restorePack] rather than [parsePack].
  danglingReference,

  /// Holds a word this app stores as an enum but cannot read back.
  ///
  /// `status` is the one that matters: a pack saying `deceaced` used to restore
  /// as `active`, because every `*FromName` helper falls back to a default. The
  /// animal would come back alive, in the breeding stock, with its reminders
  /// re-booked — a typo silently undoing a death. Nothing in the schema refuses
  /// it: no column here has a `CHECK`, so the file is the only place to notice.
  badValue,
}

class PackReject implements Exception {
  const PackReject(this.problem, [this.detail = '']);

  final PackProblem problem;
  final String detail;

  @override
  String toString() =>
      'PackReject(${problem.name}${detail.isEmpty ? '' : ', $detail'})';
}

/// A pack that has been read and validated, but not written to the database yet.
///
/// The counts are available before anything is destroyed, which is what lets
/// Settings say "this replaces the 12 animals on this phone" and mean it.
class PackRows {
  const PackRows({required this.exportedAtMs, required this.tables});

  final int? exportedAtMs;
  final Map<String, List<Map<String, Object?>>> tables;

  int countOf(String table) => tables[table]?.length ?? 0;

  int get totalRows => tables.values.fold(0, (sum, rows) => sum + rows.length);
}

/// Every row of every table, ready to encode.
///
/// The ten reads happen inside one transaction because a backup is only worth
/// what it can be restored to. Read table by table with no transaction and a
/// herd that changes while the pack is built yields two moments: the animals as
/// they were, and a dose added a second later under an animal the pack never
/// saw. That file is worse than no backup — it carries a row pointing at an
/// animal it does not contain, and [restorePack]'s transaction refuses the whole
/// thing on the foreign key, so the one restore the breeder ever needs fails on
/// a file they believed was safe. One snapshot, or nothing.
Future<Map<String, Object?>> packFrom(
  Database db, {
  int? exportedAtMs,
  bool includePhotos = true,
}) async {
  // `photos` joins the value tables here even though it is listed as
  // file-backed: its rows are what tell the archive which files to carry, and a
  // restore that put the bytes back without the rows would write files no screen
  // can reach. Declining them is only for a caller that wants the ledger alone.
  final tables = <String>[...dataTables, if (includePhotos) 'photos'];
  final rows = await db.transaction(
    (Transaction txn) async => <String, Object?>{
      for (final table in tables)
        table: _readyForTravel(table, await txn.query(table)),
    },
  );
  return <String, Object?>{
    'format': packFormat,
    'formatVersion': packFormatVersion,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAtMs ?? _nowMs(),
    'rows': rows,
  };
}

/// Two-space indent because a breeder who opens this file in a text editor is
/// looking for one animal's name, not parsing bytes.
String encodePack(Map<String, Object?> pack) =>
    const JsonEncoder.withIndent('  ').convert(pack);

/// Columns that name a file on the phone that wrote the pack, per table.
///
/// These are **dropped** on the way out rather than carried, and the reason is the
/// one fact a backup cannot promise: a path is a pointer into a filesystem that
/// belongs to one device. `animals.photo_path` has never been written by anything
/// — pictures live in their own table with their own folder — and
/// `placements.contract_file_path` is a bare file name inside this app's folder
/// for the same reason.
///
/// Carrying a contract's *name* would be fine on its own, but it would arrive on
/// the second phone naming a file that phone does not hold, and the screen would
/// say "open the contract" about nothing. So the column travels as null: the
/// handover keeps its price, its buyer and its date, and says plainly that the
/// document itself did not come with the pack. Nobody is told a file exists that
/// does not.
const Map<String, List<String>> _pathsNotWorthCarrying = <String, List<String>>{
  'animals': <String>['photo_path'],
  'placements': <String>['contract_file_path'],
};

/// One table's rows, with the columns above blanked.
List<Map<String, Object?>> _readyForTravel(
  String table,
  List<Map<String, Object?>> rows,
) {
  final drop = _pathsNotWorthCarrying[table];
  if (drop == null) return rows;
  return <Map<String, Object?>>[
    for (final row in rows)
      <String, Object?>{
        for (final entry in row.entries)
          entry.key: drop.contains(entry.key) ? null : entry.value,
      },
  ];
}

/// Reads a pack and proves it is a whole one before any row is written.
///
/// Shape is checked here; values are not. A row with a bad reference or an
/// unknown column is the database's job, and [restorePack] leaves it to the
/// transaction to reject.
PackRows parsePack(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const PackReject(PackProblem.unreadable);
  }
  if (decoded is! Map) throw const PackReject(PackProblem.unreadable);
  final Map<Object?, Object?> pack = decoded;
  if (pack['format'] != packFormat) {
    throw const PackReject(PackProblem.notAPack, 'format');
  }

  final Object? format = pack['formatVersion'];
  if (format is int && format > packFormatVersion) {
    throw PackReject(PackProblem.fromTheFuture, 'format $format');
  }
  final Object? schema = pack['schemaVersion'];
  if (schema is int && schema > schemaVersion) {
    throw PackReject(PackProblem.fromTheFuture, 'schema $schema');
  }
  // A file stamped with no schema version at all is read as one from this
  // schema: it is a hand-made or damaged file rather than an old export, and the
  // table check below is what catches it.
  final writtenAtSchema = schema is int ? schema : schemaVersion;

  final Object? rows = pack['rows'];
  if (rows is! Map) throw const PackReject(PackProblem.notAPack, 'rows');

  final tables = <String, List<Map<String, Object?>>>{};
  for (final entry in rows.entries) {
    if (entry.key case final String table) {
      // `photos` is allowed in a pack although it is not a [dataTables] table:
      // its rows travel with the bytes in the archive, and refusing them here
      // would leave a restored phone with pictures it cannot name.
      if (!dataTables.contains(table) && table != 'photos') {
        throw PackReject(PackProblem.unknownTable, table);
      }
      final List<Object?> rowsOfTable;
      if (entry.value case final List<Object?> value) {
        rowsOfTable = value;
      } else {
        throw PackReject(PackProblem.notAPack, table);
      }

      final parsed = <Map<String, Object?>>[];
      for (final row in rowsOfTable) {
        if (row case final Map<Object?, Object?> map) {
          parsed.add(Map<String, Object?>.from(map));
        } else {
          throw PackReject(PackProblem.notAPack, '$table row');
        }
      }
      _checkEnums(table, parsed);
      tables[table] = parsed;
    } else {
      throw const PackReject(PackProblem.notAPack, 'table name');
    }
  }

  // Every table this app has has to be in the file, or the restore would leave
  // rows behind without saying so. The one exception is a table newer than the
  // pack: `symptoms` arrived with schema version 2, so a pack exported by
  // version 1 never held it. Refusing that file would tell a breeder their only
  // backup is incomplete when the honest reading is that the ledger had no
  // symptoms in it yet, so a table the pack predates is restored as an empty
  // one. Nothing else is forgiven: a pack stamped with the current schema that
  // lost a table it should have carried is damaged, and D22 stands.
  for (final table in dataTables) {
    if (tables.containsKey(table)) continue;
    if (_addedAfterPack(table, writtenAtSchema)) {
      tables[table] = const <Map<String, Object?>>[];
      continue;
    }
    throw PackReject(PackProblem.missingTable, table);
  }

  // The stamp is a nicety — the restore dialog reads the date out loud — but it
  // arrives from a file someone could have edited, so it is checked rather than
  // cast. `decoded['exportedAt'] as int?` threw a TypeError straight out of
  // `parsePack` for a file holding `"exportedAt": "last week"`, which is the one
  // sentence this function is careful to give instead: a named reason, not a
  // crash on the breeder's screen.
  final Object? writtenAt = pack['exportedAt'];
  if (writtenAt != null && writtenAt is! int && writtenAt is! double) {
    throw PackReject(PackProblem.notAPack, 'exportedAt');
  }
  return PackRows(
    exportedAtMs: switch (writtenAt) {
      final int ms => ms,
      // A whole number a hand-editing tool wrote as `1759000000000.0` still means
      // the same instant, and JSON has one number type.
      final double ms => ms.round(),
      _ => null,
    },
    tables: tables,
  );
}

/// The columns this app reads back as an enum, with the words it accepts.
///
/// Written out rather than derived from the `*FromName` helpers, because those
/// helpers are precisely what hides the problem: each one falls back to a
/// default when the word is not recognised, so a restored row with a typo is
/// accepted and quietly becomes something else. The list is short and it only
/// changes when an enum does.
const Map<String, Map<String, Set<String>>> _enumColumns =
    <String, Map<String, Set<String>>>{
      'animals': <String, Set<String>>{
        'sex': <String>{'male', 'female', 'unknown'},
        'status': <String>{'active', 'sold', 'retired', 'deceased'},
      },
      'symptoms': <String, Set<String>>{
        'severity': <String>{'mild', 'moderate', 'severe'},
      },
    };

/// Refuses a pack whose rows hold a word this app cannot read back.
///
/// Called from [parsePack], before anything is written, so the answer arrives as
/// a named refusal on the restore dialog rather than as an animal that came back
/// alive and re-armed its reminders. A row that leaves the column out is fine:
/// the schema's `DEFAULT` is what fills it, and that default is a real value.
void _checkEnums(String table, List<Map<String, Object?>> rows) {
  final columns = _enumColumns[table];
  if (columns == null) return;
  for (final row in rows) {
    for (final entry in columns.entries) {
      if (!row.containsKey(entry.key)) continue;
      final value = row[entry.key];
      // A null in a `NOT NULL ... DEFAULT` column is not a word this app can
      // read either, but the insert refuses it and the restore catch already
      // says the sentence that fits.
      if (value is! String) continue;
      if (entry.value.contains(value)) continue;
      throw PackReject(PackProblem.badValue, '$table.${entry.key} = $value');
    }
  }
}

/// Tables that entered the schema after version 1, with the version that added
/// them. A pack stamped below that number is entitled not to carry them.
///
/// `symptoms` is here because it is the first table this app has grown rather
/// than shipped with; a future one joins the list, and a pack from before it
/// still restores.
const Map<String, int> _addedInSchemaVersion = <String, int>{'symptoms': 2};

/// Whether [table] was written into the schema later than the version
/// [packSchema] this file was exported at, so the file could not have held it.
bool _addedAfterPack(String table, int packSchema) {
  final added = _addedInSchemaVersion[table];
  return added != null && packSchema < added;
}

/// Replaces everything on this device with the pack, or nothing.
///
/// One transaction with `defer_foreign_keys` because the ledger is circular: an
/// animal names its litter while the litter names its dam, so mid-restore there
/// is always a row pointing at one that has not been inserted yet. Deferring
/// keeps those intermediate states legal; it does not cancel the check, it moves
/// it to COMMIT.
///
/// That is why this asks SQLite directly with `foreign_key_check` before
/// finishing. A commit that fails is not the clean end of a transaction — the
/// database stays inside it, and the next call on that handle waits forever. The
/// pack's dangling rows are therefore rejected while a rollback still works, so
/// the rows that were on the phone before the attempt are still there and the
/// database is still answering questions.
///
/// The pictures are the one table whose rows and bytes can arrive separately: a
/// pack from an older version carries no `photos` table at all, and a ZIP whose
/// files were missing carries rows with no bytes. Their rows are read back
/// before the animals go (the cascade takes them with it, measured on a real
/// database at run `38165892860`), and then the incoming rows and this phone's
/// own are merged, filtered to animals the pack kept. Neither list may lose the
/// other: the pack's rows name the files the archive wrote beside it, and the
/// phone's own rows name bytes nothing can recreate. Dropping either would hide
/// a picture that is still on the disk behind no screen at all.
///
/// The rows that came through are what this returns, because the caller has a
/// folder to sweep against them — `PhotoFiles.deleteUnbacked` — and asking the
/// database a second time what this transaction already decided would be a
/// second answer to the same question, and a slower one.
Future<List<Photo>> restorePack(Database db, PackRows pack) {
  return db.transaction<List<Photo>>((txn) async {
    await txn.execute('PRAGMA defer_foreign_keys = ON');

    final pictures = await txn.query('photos');
    // Cleared by hand rather than left to the cascade, so the outcome does not
    // depend on when SQLite fires a deferred foreign key's action.
    await txn.delete('photos');

    for (final table in dataTables.reversed) {
      await txn.delete(table);
    }

    for (final table in dataTables) {
      final rows = pack.tables[table]!;
      if (rows.isEmpty) continue;
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.abort);
      }
      await batch.commit(noResult: true);
    }

    final herd = <String>{
      for (final row in await txn.query('animals')) row['id']! as String,
    };
    // A picture row is the one row a pack can arrive without the bytes for, so
    // the two lists are merged rather than one replacing the other: the pack's
    // rows name the files the archive wrote beside it, and this phone's own rows
    // name bytes nothing can recreate. Neither list may lose the other, and the
    // herd filter is what stops either from outliving its animal.
    final source = <Map<String, Object?>>[
      ...pictures,
      ...?pack.tables['photos'],
    ];
    final kept = <Photo>[];
    final seen = <String>{};
    for (final picture in source) {
      if (!herd.contains(picture['animal_id'])) continue;
      if (picture['id'] case final String id) {
        if (!seen.add(id)) continue;
      }
      await txn.insert(
        'photos',
        picture,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      kept.add(Photo.fromMap(picture));
    }

    final dangling = await txn.rawQuery('PRAGMA foreign_key_check');
    if (dangling.isNotEmpty) {
      throw PackReject(PackProblem.danglingReference, _rowRef(dangling.first));
    }
    // Out of the transaction, not beside it: the rows are only real once the
    // commit holds, and a caller that swept its folder against a rolled-back
    // list would have deleted pictures for a restore that never happened.
    return kept;
  });
}

/// `vaccinations #7 → animals`, the shortest honest description of a bad row.
///
/// The rowid is SQLite's own and is not the record's uuid, so this is for the
/// log, not for the breeder: the screen says the restore failed and that nothing
/// on the phone moved.
String _rowRef(Map<String, Object?> row) =>
    '${row['table']} #${row['rowid']} → ${row['parent']}';

int _nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
