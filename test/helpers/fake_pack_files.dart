import 'dart:convert';
import 'dart:typed_data';

import 'package:companion/services/pack_archive.dart';
import 'package:companion/services/pack_files.dart';

/// Stands in for the share sheet and the file picker, which are Android dialogs
/// no test runner can answer.
///
/// It records every file the screen tried to share, under the name it asked for,
/// and plays back whatever import the test requested — so the screens can be
/// tested against a real database with no phone.
class FakePackFiles implements PackFiles {
  FakePackFiles({this.picked});

  /// What `pick()` hands back. Null is the breeder closing the picker.
  PickedPackFile? picked;

  /// Answers `pick()` with plain UTF-8 text, the shape of a pack written before
  /// the archive existed. Kept as a setter so a test reads as the file it means.
  set pickedText(String? text) {
    picked = text == null
        ? null
        : PickedPackFile(
            name: 'companion-pack.json',
            bytes: Uint8List.fromList(utf8.encode(text)),
          );
  }

  /// Thrown instead of sharing, for the refused-sheet message.
  Object? shareFailure;

  /// Thrown instead of picking, for the unopenable-file message.
  Object? pickFailure;

  /// Every file handed to the sheet, by the name it was given.
  final Map<String, List<int>> shared = <String, List<int>>{};

  /// The ledger of the last pack the screen shared, decoded out of its archive.
  String get sharedJson => decodePackArchive(shared.values.last).json;

  /// The pictures of the last pack the screen shared, as `folder/file` → bytes.
  Map<String, List<int>> get sharedPhotos =>
      decodePackArchive(shared.values.last).photos;

  @override
  Future<String> shareBytes(String name, List<int> bytes) async {
    if (shareFailure != null) throw shareFailure!;
    shared[name] = bytes;
    return name;
  }

  @override
  Future<PickedPackFile?> pick() async {
    if (pickFailure != null) throw pickFailure!;
    return picked;
  }
}
