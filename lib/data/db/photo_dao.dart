import '../models/photo.dart';
import 'record_dao.dart';

class PhotoDao extends RecordDao<Photo> {
  PhotoDao(super.db);

  @override
  String get table => 'photos';

  @override
  Photo fromMap(Map<String, Object?> row) => Photo.fromMap(row);

  @override
  Map<String, Object?> toMap(Photo record) => record.toMap();

  /// Oldest picture first: a breeder's photo strip reads as a growth record,
  /// and the newest frame goes at the end of that sentence rather than in front.
  ///
  /// The same list answers "which files go with this animal when it is deleted"
  /// — the foreign key removes the rows, and only this app can remove the bytes.
  Future<List<Photo>> forAnimal(String animalId) =>
      byColumn('animal_id', animalId, orderBy: 'created_at ASC');

  /// The newest picture of every animal, keyed by animal id.
  ///
  /// One query for the whole herd rather than one per card: the herd list is a
  /// lazy `ListView`, so a per-card read would start a database call in the
  /// frame that first built that row, in the middle of a scroll. The newest is
  /// what a card shows — a breeder's card is a portrait of the dog now, not a
  /// growth chart.
  Future<Map<String, Photo>> newestPerAnimal() async {
    final rows = await db.query('photos', orderBy: 'created_at ASC');
    final newest = <String, Photo>{};
    for (final row in rows) {
      final photo = fromMap(row);
      // Ascending order, so the last one written for an animal wins and no
      // comparison is needed here.
      newest[photo.animalId] = photo;
    }
    return newest;
  }
}
