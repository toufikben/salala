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
}
