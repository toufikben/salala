import '../models/symptom.dart';
import 'record_dao.dart';

class SymptomDao extends RecordDao<Symptom> {
  SymptomDao(super.db);

  @override
  String get table => 'symptoms';

  @override
  Symptom fromMap(Map<String, Object?> row) => Symptom.fromMap(row);

  @override
  Map<String, Object?> toMap(Symptom record) => record.toMap();

  /// Newest sighting first: the ledger reads like a case history, and the sign
  /// that matters is the one from this morning.
  Future<List<Symptom>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'observed_at DESC');
}
