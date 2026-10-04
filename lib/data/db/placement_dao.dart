import '../models/placement.dart';
import 'record_dao.dart';

class PlacementDao extends RecordDao<Placement> {
  PlacementDao(super.db);

  @override
  String get table => 'placements';

  @override
  Placement fromMap(Map<String, Object?> row) => Placement.fromMap(row);

  @override
  Map<String, Object?> toMap(Placement record) => record.toMap();

  Future<List<Placement>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'placed_date DESC');

  Future<Placement?> forBuyer(String buyerId) async {
    final rows = await db.query(
      'placements',
      where: 'buyer_id = ?',
      whereArgs: <Object?>[buyerId],
      orderBy: 'placed_date DESC',
    );
    return rows.isEmpty ? null : fromMap(rows.first);
  }
}
