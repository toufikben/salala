import 'package:salala/services/pack_files.dart';

/// Stands in for the share sheet and the file picker, which are Android dialogs
/// no test runner can answer.
///
/// It records every pack the screen tried to share and plays back whatever
/// import the test asked for, so the Settings screen can be tested against a
/// real database with no phone.
class FakePackFiles implements PackFiles {
  FakePackFiles({this.pickedText});

  /// What `pick()` hands back. Null is the breeder closing the picker.
  String? pickedText;

  /// Thrown instead of sharing, for the refused-sheet message.
  Object? shareFailure;

  /// Thrown instead of picking, for the unopenable-file message.
  Object? pickFailure;

  /// Every pack the screen handed to the sheet, oldest first.
  final List<String> shared = <String>[];

  @override
  Future<String> share(String json, {required DateTime now}) async {
    if (shareFailure != null) throw shareFailure!;
    shared.add(json);
    return 'salala-pack-test.json';
  }

  @override
  Future<String?> pick() async {
    if (pickFailure != null) throw pickFailure!;
    return pickedText;
  }
}
