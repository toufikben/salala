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

  /// Writes one dose per animal, all of it or none of it.
  ///
  /// A litter is vaccinated in one sitting: the vial is open, the breeder holds
  /// one puppy and then the next, and typing nine identical rows on a phone
  /// between holds is how a litter ends up half-recorded. The transaction is the
  /// promise — a refusal on the sixth row leaves the first five unwritten, so the
  /// ledger never carries a partial sitting nobody can tell from a real one.
  ///
  /// Returns the rows as stored, in the order they were given, because each one
  /// gains an id here and the caller has to book a reminder against it.
  Future<List<Vaccination>> createAll(
    List<Vaccination> records, {
    int? nowMs,
  }) async {
    if (records.isEmpty) return const <Vaccination>[];
    final stamp = nowMs ?? _nowMs();
    return db.transaction((txn) async {
      final written = <Vaccination>[];
      for (final record in records) {
        final row = <String, Object?>{...toMap(record)};
        stampRecordRow(row, stamp, isNew: true);
        await txn.insert(table, row);
        written.add(fromMap(row));
      }
      return written;
    });
  }
}
