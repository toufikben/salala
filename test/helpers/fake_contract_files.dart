import 'dart:typed_data';

import 'package:companion/services/contract_files.dart';

/// Stands in for the document picker and the contract folder, neither of which a
/// test runner can answer.
///
/// It records what was stored and what was asked for, so a test can prove the row
/// and the stored bytes are about one document. `pathFor` answers null unless the
/// test seeded [bytes], which is the shipped behaviour for a file that is not on
/// this phone — the state a restored ledger is in.
class FakeContractFiles implements ContractFiles {
  FakeContractFiles({Map<String, List<int>>? bytes})
    : bytes = bytes ?? <String, List<int>>{};

  /// What `pick()` hands back. Null is the breeder closing the picker.
  PickedContract? nextPicked;

  /// Thrown instead of picking, for the picker that refuses.
  Object? pickFailure;

  /// Thrown instead of storing, for the refusal the form has to say out loud.
  Object? storeFailure;

  /// The folder's contents, as `<animalId>/<fileName>` → bytes.
  final Map<String, List<int>> bytes;

  /// Every store, as `<animalId>/<fileName>`, in the order they happened.
  final List<String> stored = <String>[];

  /// Every single-file delete, as `<animalId>/<fileName>`.
  final List<String> deleted = <String>[];

  /// Every whole-folder clear, by animal id.
  final List<String> clearedFolders = <String>[];

  /// Every path the screen asked for, as `<animalId>/<fileName>`.
  final List<String> pathsAsked = <String>[];

  /// Every document the screen asked to open, as `<animalId>/<fileName>`.
  final List<String> opened = <String>[];

  /// What the shipped class would hand a share sheet, by `<animalId>/<fileName>`.
  final List<String> shared = <String>[];

  static PickedContract contract(String name, {int bytes = 1024}) =>
      PickedContract(name: name, bytes: Uint8List(bytes));

  @override
  Future<PickedContract?> pick() async {
    if (pickFailure != null) throw pickFailure!;
    return nextPicked;
  }

  @override
  Future<String> store(String animalId, PickedContract contract) async {
    if (storeFailure != null) throw storeFailure!;
    // Named from what this fake was handed rather than from the clock: an
    // assertion on the row and one on [stored] have to mean one document.
    final fileName = '${contract.name}-${contract.bytes.length}';
    stored.add('$animalId/$fileName');
    bytes['$animalId/$fileName'] = List<int>.from(contract.bytes);
    return fileName;
  }

  @override
  Future<void> delete(String animalId, String fileName) async {
    deleted.add('$animalId/$fileName');
    bytes.remove('$animalId/$fileName');
  }

  @override
  Future<void> deleteAll(String animalId) async {
    clearedFolders.add(animalId);
    bytes.removeWhere((key, _) => key.startsWith('$animalId/'));
  }

  @override
  Future<String?> pathFor(String animalId, String fileName) async {
    pathsAsked.add('$animalId/$fileName');
    final content = bytes['$animalId/$fileName'];
    return content == null ? null : '/contracts/$animalId/$fileName';
  }

  @override
  Future<Uint8List?> readBytes(String animalId, String fileName) async {
    opened.add('$animalId/$fileName');
    final content = bytes['$animalId/$fileName'];
    return content == null ? null : Uint8List.fromList(content);
  }
}
