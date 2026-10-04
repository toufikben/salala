import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Shared CRUD for a single-table record.
///
/// `created_at` / `updated_at` are only touched when the row actually carries
/// those columns, which is what lets an append-only table (`weight_entries`)
/// use the same base as the mutable ones.
abstract class RecordDao<T> {
  RecordDao(this.db);

  final Database db;

  String get table;

  T fromMap(Map<String, Object?> row);

  Map<String, Object?> toMap(T record);

  /// Empty id means "new record" — the dao assigns a uuid. Imported rows keep
  /// the id they arrived with.
  Future<T> create(T record, {int? nowMs}) async {
    final row = <String, Object?>{...toMap(record)};
    stampRecordRow(row, nowMs ?? _nowMs(), isNew: true);
    await db.insert(table, row);
    return fromMap(row);
  }

  Future<int> update(T record, {int? nowMs}) {
    final row = <String, Object?>{...toMap(record)};
    final id = row['id'];
    stampRecordRow(row, nowMs ?? _nowMs(), isNew: false);
    return db.update(table, row, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<int> delete(String id) =>
      db.delete(table, where: 'id = ?', whereArgs: <Object?>[id]);

  Future<T?> findById(String id) async {
    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : fromMap(rows.first);
  }

  Future<List<T>> all({String? orderBy}) async {
    final rows = await db.query(table, orderBy: orderBy);
    return rows.map(fromMap).toList();
  }

  Future<List<T>> byColumn(
    String column,
    Object? value, {
    String? orderBy,
  }) async {
    final rows = await db.query(
      table,
      where: '$column = ?',
      whereArgs: <Object?>[value],
      orderBy: orderBy,
    );
    return rows.map(fromMap).toList();
  }
}

/// Assigns the id and the timestamps a row needs, skipping columns the table
/// does not have — which is what lets an append-only table (`weight_entries`)
/// share this base with the mutable ones.
void stampRecordRow(Map<String, Object?> row, int now, {required bool isNew}) {
  final id = row['id'] as String?;
  if (isNew && (id == null || id.isEmpty)) row['id'] = const Uuid().v4();
  if (isNew && row.containsKey('created_at')) row['created_at'] = now;
  if (row.containsKey('updated_at')) row['updated_at'] = now;
}

int _nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
