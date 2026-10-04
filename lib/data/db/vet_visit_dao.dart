import '../models/vet_visit.dart';
import 'record_dao.dart';

class VetVisitDao extends RecordDao<VetVisit> {
  VetVisitDao(super.db);

  @override
  String get table => 'vet_visits';

  @override
  VetVisit fromMap(Map<String, Object?> row) => VetVisit.fromMap(row);

  @override
  Map<String, Object?> toMap(VetVisit record) => record.toMap();

  Future<List<VetVisit>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'visit_date DESC');
}
