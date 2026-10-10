import 'dart:typed_data';

import 'package:salala/services/photo_files.dart';

/// Stands in for the gallery picker and the folder under the app's documents,
/// neither of which a test runner can answer.
///
/// It records which file name went with which animal, and which names the screen
/// then asked a path for, so a test can prove the ledger row and the stored bytes
/// are about one picture. `pathFor` always answers null: a real read
/// (`Image.file`) never completes inside a fake-async zone, which is the same
/// reason every database behind these screens is waited on with `settleRealIo`.
/// So the strip is driven through the blank it shows when a file is missing, and
/// the bytes are `photo_files_test.dart`'s to prove against a real folder.
class FakePhotoFiles implements PhotoFiles {
  FakePhotoFiles();

  /// What `pick()` hands back. Null is the breeder closing the picker.
  PickedPhoto? nextPicked;

  /// Thrown instead of storing, for the refusal a screen has to say out loud.
  PhotoRefused? storeRefusal;

  /// Thrown instead of deleting, for the file that would not go.
  Object? deleteFailure;

  /// Every store, as `<animalId>/<fileName>`, in the order they happened.
  final List<String> stored = <String>[];

  /// Every single-file delete, as `<animalId>/<fileName>`.
  final List<String> deleted = <String>[];

  /// Every whole-folder clear, by animal id.
  final List<String> clearedFolders = <String>[];

  /// Every path the screen asked for, as `<animalId>/<fileName>` — what the row
  /// told this app the picture was called. Compared against [stored], it is how
  /// a test proves the ledger and the folder agree on one name.
  final List<String> pathsAsked = <String>[];

  static PickedPhoto photo(String name, {int bytes = 1024}) =>
      PickedPhoto(name: name, bytes: Uint8List(bytes));

  @override
  Future<PickedPhoto?> pick() async => nextPicked;

  @override
  Future<String> store(String animalId, PickedPhoto photo) async {
    if (storeRefusal != null) throw storeRefusal!;
    // The name the shipped class would have written, taken from what it was
    // handed rather than from the clock: a test asserts on the row and on this
    // list, and both have to mean the same picture.
    final fileName = '${photo.name}-${photo.bytes.length}';
    stored.add('$animalId/$fileName');
    return fileName;
  }

  @override
  Future<void> delete(String animalId, String fileName) async {
    if (deleteFailure != null) throw deleteFailure!;
    deleted.add('$animalId/$fileName');
  }

  @override
  Future<void> deleteAll(String animalId) async {
    clearedFolders.add(animalId);
  }

  @override
  Future<String?> pathFor(String animalId, String fileName) async {
    pathsAsked.add('$animalId/$fileName');
    return null;
  }
}
