import 'dart:convert';

import 'package:salala/services/pack_files.dart';

/// Stands in for the share sheet and the file picker, which are Android dialogs
/// no test runner can answer.
///
/// It records every file the screen tried to share, under the name it asked for,
/// and plays back whatever import the test requested — so the screens can be
/// tested against a real database with no phone.
class FakePackFiles implements PackFiles {
  FakePackFiles({this.pickedText});

  /// What `pick()` hands back. Null is the breeder closing the picker.
  String? pickedText;

  /// Thrown instead of sharing, for the refused-sheet message.
  Object? shareFailure;

  /// Thrown instead of picking, for the unopenable-file message.
  Object? pickFailure;

  /// Every file handed to the sheet, by the name it was given.
  final Map<String, List<int>> shared = <String, List<int>>{};

  /// The JSON of the last pack the screen shared, decoded for assertions.
  String get sharedJson => utf8.decode(shared.values.last);

  @override
  Future<String> shareBytes(String name, List<int> bytes) async {
    if (shareFailure != null) throw shareFailure!;
    shared[name] = bytes;
    return name;
  }

  @override
  Future<String?> pick() async {
    if (pickFailure != null) throw pickFailure!;
    return pickedText;
  }
}
