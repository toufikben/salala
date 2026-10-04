import '../models/vaccination.dart';
import 'record_dao.dart';

class VaccinationDao extends RecordDao<Vaccination> {
  VaccinationDao(super.db);

  @override
  String get table => 'vaccinations';

  @override
  Vaccination fromMap(Map<String, Object?> row) => Vaccination.fromMap(row);

  @override
  Map<String, Object?> toMap(Vaccination record) => record.toMap();

  Future<List<Vaccination>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'date_administered DESC');

  /// Used by the notification scheduler and the home screen badge.
  Future<List<Vaccination>> dueBefore(int cutoffMs) async {
    final rows = await db.query(
      'vaccinations',
      where: 'next_due_date IS NOT NULL AND next_due_date <= ?',
      whereArgs: <Object?>[cutoffMs],
      orderBy: 'next_due_date ASC',
    );
    return rows.map(fromMap).toList();
  }
}
