import '../models/weight_entry.dart';
import 'record_dao.dart';

class WeightDao extends RecordDao<WeightEntry> {
  WeightDao(super.db);

  @override
  String get table => 'weight_entries';

  @override
  WeightEntry fromMap(Map<String, Object?> row) => WeightEntry.fromMap(row);

  @override
  Map<String, Object?> toMap(WeightEntry record) => record.toMap();

  /// Chart input: oldest first so a polyline can be drawn without reversing.
  Future<List<WeightEntry>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'measured_at ASC');

  Future<WeightEntry?> latestFor(String animalId) async {
    final rows = await db.query(
      'weight_entries',
      where: 'animal_id = ?',
      whereArgs: <Object?>[animalId],
      orderBy: 'measured_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : fromMap(rows.first);
  }
}
