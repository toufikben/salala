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

  /// How many whelpings the delete of [damId] would take with it.
  ///
  /// `litters.dam_id` is `ON DELETE CASCADE`, so a dam's deletion removes her
  /// whelpings. The confirmation dialog says how many before it happens.
  Future<int> countForDam(String damId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM litters WHERE dam_id = ?',
      <Object?>[damId],
    );
    return rows.first['c']! as int;
  }

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

  /// Registers more puppies for a whelping already in the ledger.
  ///
  /// A breeder registers five and the sixth arrives two hours later, or the
  /// litter is entered before the count is known; without this the only way to
  /// add her was to delete the litter — losing its dates and the puppies'
  /// lineage — and type it again. Names continue the numbering the form uses
  /// (`<litter> 1`, `<litter> 2`), so a second visit reads as one litter rather
  /// than two batches of the same names.
  Future<List<Animal>> addPuppies(
    Litter litter,
    int count, {
    int? nowMs,
  }) async {
    if (count <= 0) return const <Animal>[];
    final now = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;

    final damRows = await db.query(
      'animals',
      columns: <String>['species', 'breed'],
      where: 'id = ?',
      whereArgs: <Object?>[litter.damId],
      limit: 1,
    );
    // `litters.dam_id` is `ON DELETE CASCADE`, so a litter in the ledger always
    // has its dam; an empty answer here is a bug, not a state to paper over.
    if (damRows.isEmpty) {
      throw StateError('Litter ${litter.id} has no dam ${litter.damId}');
    }
    final species = damRows.first['species']! as String;
    final breed = damRows.first['breed'] as String?;

    final counted = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM animals WHERE litter_id = ?',
      <Object?>[litter.id],
    );
    final start = (counted.first['c']! as int) + 1;

    final created = <Animal>[];
    await db.transaction((txn) async {
      for (var index = start; index < start + count; index++) {
        final puppy = Animal(
          id: '',
          name: '${litter.name} $index',
          species: species,
          breed: breed,
          sex: Sex.unknown,
          status: AnimalStatus.active,
          birthDate: litter.whelpingDate,
          litterId: litter.id,
          damId: litter.damId,
          sireId: litter.sireId,
          createdAt: 0,
          updatedAt: 0,
        );
        final row = <String, Object?>{...puppy.toMap()};
        stampRecordRow(row, now, isNew: true);
        await txn.insert('animals', row);
        created.add(Animal.fromMap(row));
      }
    });
    return created;
  }

  /// Carries an edit of [previous] into the puppies it already registered.
  ///
  /// A puppy's birthday is copied from the whelping date and its parents are
  /// stamped from the litter at registration, so a correction that stayed in the
  /// litter row would leave the herd telling a different story from the whelping
  /// it came from — and the puppy's own pack would print the two side by side.
  /// Only rows that still hold the old value are touched, so a birthday the
  /// breeder corrected by hand on one puppy survives.
  Future<void> retargetPuppies({
    required Litter previous,
    required Litter updated,
    int? nowMs,
  }) async {
    final now = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    if (previous.whelpingDate != updated.whelpingDate) {
      await db.rawUpdate(
        'UPDATE animals SET birth_date = ?, updated_at = ? '
        'WHERE litter_id = ? AND birth_date IS ?',
        <Object?>[updated.whelpingDate, now, updated.id, previous.whelpingDate],
      );
    }
    if (previous.damId != updated.damId || previous.sireId != updated.sireId) {
      await db.rawUpdate(
        'UPDATE animals SET dam_id = ?, sire_id = ?, updated_at = ? '
        'WHERE litter_id = ? AND dam_id = ? AND sire_id IS ?',
        <Object?>[
          updated.damId,
          updated.sireId,
          now,
          updated.id,
          previous.damId,
          previous.sireId,
        ],
      );
    }
  }
}
