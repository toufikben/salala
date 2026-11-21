import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'photo_files.dart' show photoFolder;

/// A document the breeder attached to a handover: signed contract, deposit slip,
/// vaccination card photographed at the gate.
class PickedContract {
  const PickedContract({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get length => bytes.length;
}

/// A contract refused on the way in, with the sentence the form shows.
enum ContractProblem { tooLarge }

class ContractRefused implements Exception {
  const ContractRefused(this.problem, [this.detail = '']);

  final ContractProblem problem;
  final String detail;

  @override
  String toString() => 'ContractRefused(${problem.name}, $detail)';
}

/// Fifteen megabytes. A scanned contract is one or two; a phone-photographed
/// four-page agreement is eight. Anything past this is a video the breeder
/// tapped by accident, and storing it would fill a phone's storage with the one
/// file the app can never show inline.
const int maxContractBytes = 15 * 1024 * 1024;

/// The folder every contract lives under, beside `photos`.
///
/// Named once because two things outside this file read it: the backup
/// exclusions in `android/app/src/main/res/xml/`, which are a privacy claim about
/// a path, and `contract_files_test.dart`, which checks the two still agree.
const String contractsDirectoryName = 'contracts';

/// A file name a placement row is allowed to point at: one bare name, no
/// separators, no parent hops. The same rule `photos` rows live under, and for
/// the same reason — the name came from a picker or from a pack file.
bool isStorableContractName(String fileName) =>
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9._ -]{0,119}$').hasMatch(fileName) &&
    !fileName.contains('..');

/// The extension worth keeping from a name a picker produced, or an empty string.
///
/// Filtered to letters and digits rather than trusted: the name came from another
/// app or from a file a breeder renamed, and it is about to become part of a name
/// this app writes. `scan.<b>.pdf` is a file name that is also a browser payload.
String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  final raw = name.substring(dot + 1).toLowerCase();
  final clean = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
  // Four is enough for `.jpeg`, `.heic`, `.docx`, and past that it is not an
  // extension anyway.
  return clean.length > 4 ? clean.substring(0, 4) : clean;
}

/// Where a handover's contract lives, and how it gets there.
///
/// Behind a seam for the same reason the pictures are: what a contract *means* is
/// decided and tested against a real database (`data_pack.dart` drops the column,
/// `placement_dialog.dart` writes it), and this is the part that needs a phone.
///
/// The rule the whole class rests on is the one the pictures use: a
/// `placements.contract_file_path` row holds a **bare file name**, the bytes live
/// under one folder per animal, and nothing a row says can name a path outside
/// the folder this app owns. A row written by an older build could hold an
/// absolute path from the phone that made it; it resolves to nothing here rather
/// than being opened, which is why the screen reads "not on this phone".
abstract class ContractFiles {
  const ContractFiles();

  /// The document the breeder chose, or null if they backed out.
  Future<PickedContract?> pick();

  /// Copies [contract] into the animal's folder and returns the bare file name to
  /// store on the row. Throws [ContractRefused] for a file this app will not keep.
  Future<String> store(String animalId, PickedContract contract);

  /// Removes one contract. A missing file is not an error.
  Future<void> delete(String animalId, String fileName);

  /// Removes every contract of one animal, for the delete that takes the animal
  /// with it.
  Future<void> deleteAll(String animalId);

  /// The path to open, or null when the file is not on this phone.
  Future<String?> pathFor(String animalId, String fileName);

  /// The document's bytes, or null when the file is not on this phone.
  ///
  /// Bytes rather than a path for the one thing the app does with a contract —
  /// hand it to another app through the share sheet — so that no screen has to
  /// reach for `dart:io`, and so a test can prove the hand-out without a disk.
  Future<Uint8List?> readBytes(String animalId, String fileName);
}

class SystemContractFiles extends ContractFiles {
  /// Overridable so the file rules are testable on a host without a phone.
  const SystemContractFiles({this.directory});

  final Future<String> Function()? directory;

  Future<String> get _root async {
    final base = await (directory ?? _documents)();
    return p.join(base, contractsDirectoryName);
  }

  static Future<String> _documents() async =>
      (await getApplicationDocumentsDirectory()).path;

  Future<String> _folder(String animalId) async =>
      p.join(await _root, photoFolder(animalId));

  @override
  Future<PickedContract?> pick() async {
    // No type filter on purpose. A signed contract arrives as a PDF, a scan as a
    // JPEG, a photographed page as HEIC from a phone that has no idea; a filter
    // that hid one of those reads as the app refusing the document.
    final XFile? file = await openFile();
    if (file == null) return null;
    return PickedContract(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<String> store(String animalId, PickedContract contract) async {
    if (contract.length > maxContractBytes) {
      throw ContractRefused(ContractProblem.tooLarge, '${contract.length}');
    }
    final folder = await _folder(animalId);
    await Directory(folder).create(recursive: true);
    // Named here rather than kept from the source: two contracts may both be
    // called `contract.pdf`, and the animal's own folder would then hold one of
    // them. The extension is the only part of the old name worth carrying.
    final extension = _extensionOf(contract.name);
    final name =
        '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${contract.bytes.length}${extension.isEmpty ? '' : '.$extension'}';
    // Belts and braces: the name is built here from two numbers and an
    // extension, so it cannot fail the rule. If it ever does, that is a bug in
    // this file rather than a document the breeder chose, and a sentence about
    // her file being too large would be a lie about the wrong thing.
    if (!isStorableContractName(name)) {
      throw StateError('a generated contract name was not storable: $name');
    }
    await File(p.join(folder, name)).writeAsBytes(contract.bytes, flush: true);
    return name;
  }

  @override
  Future<void> delete(String animalId, String fileName) async {
    if (!isStorableContractName(fileName)) return;
    final file = File(p.join(await _folder(animalId), fileName));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteAll(String animalId) async {
    final folder = Directory(await _folder(animalId));
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  @override
  Future<String?> pathFor(String animalId, String fileName) async {
    if (!isStorableContractName(fileName)) return null;
    final file = File(p.join(await _folder(animalId), fileName));
    return await file.exists() ? file.path : null;
  }

  @override
  Future<Uint8List?> readBytes(String animalId, String fileName) async {
    if (!isStorableContractName(fileName)) return null;
    final file = File(p.join(await _folder(animalId), fileName));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
