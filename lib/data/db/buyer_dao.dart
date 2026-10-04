import '../models/buyer.dart';
import 'record_dao.dart';

class BuyerDao extends RecordDao<Buyer> {
  BuyerDao(super.db);

  @override
  String get table => 'buyers';

  @override
  Buyer fromMap(Map<String, Object?> row) => Buyer.fromMap(row);

  @override
  Map<String, Object?> toMap(Buyer record) => record.toMap();

  Future<List<Buyer>> alphabetical() => all(orderBy: 'name COLLATE NOCASE ASC');
}
