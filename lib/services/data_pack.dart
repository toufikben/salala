import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/db/schema.dart';

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
/// Photos are **not** inside. A `photo_path` travels as the text it is, so
/// restoring brings the ledger back and leaves the pictures on the old phone.
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

  /// JSON, but not a Salala pack: no format tag, or a body of the wrong shape.
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
Future<Map<String, Object?>> packFrom(Database db, {int? exportedAtMs}) async {
  return <String, Object?>{
    'format': packFormat,
    'formatVersion': packFormatVersion,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAtMs ?? _nowMs(),
    'rows': <String, Object?>{
      for (final table in dataTables) table: await db.query(table),
    },
  };
}

/// Two-space indent because a breeder who opens this file in a text editor is
/// looking for one animal's name, not parsing bytes.
String encodePack(Map<String, Object?> pack) =>
    const JsonEncoder.withIndent('  ').convert(pack);

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

  final Object? rows = pack['rows'];
  if (rows is! Map) throw const PackReject(PackProblem.notAPack, 'rows');

  final tables = <String, List<Map<String, Object?>>>{};
  for (final entry in rows.entries) {
    if (entry.key case final String table) {
      if (!dataTables.contains(table)) {
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
      tables[table] = parsed;
    } else {
      throw const PackReject(PackProblem.notAPack, 'table name');
    }
  }

  for (final table in dataTables) {
    if (!tables.containsKey(table)) {
      throw PackReject(PackProblem.missingTable, table);
    }
  }

  return PackRows(exportedAtMs: decoded['exportedAt'] as int?, tables: tables);
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
Future<void> restorePack(Database db, PackRows pack) {
  return db.transaction((txn) async {
    await txn.execute('PRAGMA defer_foreign_keys = ON');

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

    final dangling = await txn.rawQuery('PRAGMA foreign_key_check');
    if (dangling.isNotEmpty) {
      throw PackReject(PackProblem.danglingReference, _rowRef(dangling.first));
    }
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
