import 'package:equatable/equatable.dart';

/// A picture of one animal, stored as a file this app owns.
///
/// The row holds a bare `fileName`, never a path: the bytes live in one folder
/// per animal under the app's documents, and `PhotoFiles` is the only thing that
/// turns the two back into a file. That is what keeps a ledger restored on a
/// second phone from reaching for pictures it was never given.
///
/// Written once and never edited, so there is no `copyWith` and no
/// `updated_at` — see the note above the table in `schema.dart`.
class Photo extends Equatable {
  const Photo({
    required this.id,
    required this.animalId,
    required this.fileName,
    required this.createdAt,
  });

  final String id;
  final String animalId;
  final String fileName;

  /// When this app took the copy, which is the order the strip is shown in.
  /// Not the camera's date: that needs EXIF, and a picture of a litter that
  /// arrived by WhatsApp has no honest answer for when the puppy was born.
  final int createdAt;

  static Photo fromMap(Map<String, Object?> map) {
    return Photo(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      fileName: map['file_name']! as String,
      createdAt: map['created_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'file_name': fileName,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, animalId, fileName, createdAt];
}
