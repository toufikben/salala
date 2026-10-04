import '../models/animal.dart';
import 'record_dao.dart';

class AnimalDao extends RecordDao<Animal> {
  AnimalDao(super.db);

  @override
  String get table => 'animals';

  @override
  Animal fromMap(Map<String, Object?> row) => Animal.fromMap(row);

  @override
  Map<String, Object?> toMap(Animal record) => record.toMap();

  /// Home list: breeding stock and companions together, known ages first.
  Future<List<Animal>> findAll({String? species, AnimalStatus? status}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (species != null) {
      where.add('species = ?');
      args.add(species);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    final rows = await db.query(
      'animals',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'birth_date IS NULL, birth_date DESC, created_at DESC',
    );
    return rows.map(fromMap).toList();
  }

  Future<List<Animal>> findBreedingStock() =>
      byColumn('is_breeding_stock', 1, orderBy: 'name COLLATE NOCASE ASC');

  Future<List<Animal>> findOffspring(String litterId) =>
      byColumn('litter_id', litterId, orderBy: 'name COLLATE NOCASE ASC');

  Future<List<String>> distinctSpecies() async {
    final rows = await db.rawQuery(
      'SELECT DISTINCT species FROM animals ORDER BY species COLLATE NOCASE ASC',
    );
    return rows.map((r) => r['species']! as String).toList();
  }

  Future<int> count() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM animals');
    return rows.first['c']! as int;
  }
}
