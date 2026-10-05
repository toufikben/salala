import '../models/health_test.dart';
import 'record_dao.dart';

class HealthTestDao extends RecordDao<HealthTest> {
  HealthTestDao(super.db);

  @override
  String get table => 'health_tests';

  @override
  HealthTest fromMap(Map<String, Object?> row) => HealthTest.fromMap(row);

  @override
  Map<String, Object?> toMap(HealthTest record) => record.toMap();

  Future<List<HealthTest>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'test_date DESC');

  /// Certificates that lapse on or before [cutoffMs], oldest first. A screening
  /// with no expiry (an OFA grade is permanent) is not a reminder and never
  /// comes back from here. Used by the reminder rebuild at launch.
  Future<List<HealthTest>> expiringBy(int cutoffMs) async {
    final rows = await db.query(
      'health_tests',
      where: 'valid_until IS NOT NULL AND valid_until <= ?',
      whereArgs: <Object?>[cutoffMs],
      orderBy: 'valid_until ASC',
    );
    return rows.map(fromMap).toList();
  }
}
