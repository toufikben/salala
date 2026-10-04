import '../models/litter.dart';
import 'record_dao.dart';

class LitterDao extends RecordDao<Litter> {
  LitterDao(super.db);

  @override
  String get table => 'litters';

  @override
  Litter fromMap(Map<String, Object?> row) => Litter.fromMap(row);

  @override
  Map<String, Object?> toMap(Litter record) => record.toMap();

  Future<List<Litter>> forDam(String damId) => byColumn(
    'dam_id',
    damId,
    orderBy: 'whelping_date IS NULL, whelping_date DESC',
  );

  Future<List<Litter>> recent() => all(
    orderBy: 'whelping_date IS NULL, whelping_date DESC, created_at DESC',
  );
}
