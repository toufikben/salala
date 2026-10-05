import '../models/animal.dart';
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

  /// The litters an animal got rather than carried.
  ///
  /// A sire's paper value is this list, so the buyer's pack has to ask for it;
  /// the same newest-first rule as [forDam] so the two read as one history.
  Future<List<Litter>> forSire(String sireId) => byColumn(
    'sire_id',
    sireId,
    orderBy: 'whelping_date IS NULL, whelping_date DESC',
  );

  Future<List<Litter>> recent() => all(
    orderBy: 'whelping_date IS NULL, whelping_date DESC, created_at DESC',
  );

  /// Writes the litter and registers its puppies in one transaction.
  ///
  /// A breeder records a whelping once and never re-types it, so a litter whose
  /// puppies vanished — or puppies pointing at a litter that was never written —
  /// is exactly the half-record a paper ledger cannot produce. The lineage
  /// columns are stamped here rather than trusted from the caller so every puppy
  /// in the database agrees with its litter about who its parents were.
  Future<Litter> createWithPuppies(
    Litter litter,
    List<Animal> puppies, {
    int? nowMs,
  }) async {
    final now = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final litterRow = <String, Object?>{...toMap(litter)};
    stampRecordRow(litterRow, now, isNew: true);
    final created = Litter.fromMap(litterRow);

    await db.transaction((txn) async {
      await txn.insert('litters', litterRow);
      for (final puppy in puppies) {
        final linked = puppy.copyWith(
          litterId: created.id,
          damId: created.damId,
          sireId: created.sireId,
        );
        final row = <String, Object?>{...linked.toMap()};
        stampRecordRow(row, now, isNew: true);
        await txn.insert('animals', row);
      }
    });

    return created;
  }
}
