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
}
