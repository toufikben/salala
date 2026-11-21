import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';

import 'data_pack.dart';
import 'photo_files.dart';

/// The pack as it travels: `pack.json` plus the pictures it names.
///
/// A pack used to be the JSON alone, and the pictures stayed behind on the phone
/// that exported it — the one part of a restore that could not be recreated.
/// They travel beside the ledger now, in the same ZIP, so a new phone gets the
/// rows *and* the bytes, and `photos.file_name` still points at a real file.
///
/// The container is deliberately dumb: two shapes of entry, nothing else.
/// * `pack.json` — exactly what [encodePack] writes, so the format is unchanged
///   and every file this app has already exported is still readable.
/// * `photos/<folder>/<file name>` — the bytes, under the same folder name the
///   phone would have used itself (`photoFolder`), never a path from the file.
const String packEntryName = 'pack.json';
const String packPhotoPrefix = 'photos/';

/// ZIP files start with `PK\x03\x04`. The local-file header is the first thing a
/// writer emits, and no JSON pack can begin with those four bytes, so this is a
/// safe test on a file a breeder could have renamed.
bool isZipBytes(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4B &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

/// A pack read out of a container: the ledger, and any bytes that came with it.
class PackArchive {
  const PackArchive({required this.json, required this.photos});

  /// The text [parsePack] reads. Unchanged from the JSON-only format.
  final String json;

  /// `'<photo folder>/<file name>'` → bytes. Empty for an old JSON pack, and for
  /// a ZIP whose pictures were all missing from the phone that wrote it.
  final Map<String, List<int>> photos;
}

/// Writes [json] and [photos] into one ZIP.
///
/// The pictures are already compressed — a JPEG deflated again is a slower
/// export for a fraction of a percent — so they are stored, and the JSON is the
/// only thing that pays for compression.
Uint8List encodePackArchive(String json, Map<String, List<int>> photos) {
  final archive = Archive();
  final ledger = utf8.encode(json);
  archive.addFile(ArchiveFile(packEntryName, ledger.length, ledger));

  for (final entry in photos.entries) {
    final name = '$packPhotoPrefix${entry.key}';
    // A name the phone would refuse to write is a name it must not carry either:
    // an archive entry is a string from a file someone else could have written,
    // and `..` in it would reach outside the folder this app owns.
    if (!_isSafeEntry(name)) continue;
    archive.addFile(ArchiveFile(name, entry.value.length, entry.value));
  }

  return ZipEncoder().encodeBytes(archive);
}

/// Reads a container back, or throws [PackReject] for a file that is not one.
///
/// Unknown entries are ignored rather than refused: a future version adding
/// `notes/` to the same ZIP should not make today's app call the backup damaged.
/// A corrupt archive, a missing `pack.json`, or one whose bytes are not UTF-8 is
/// a named rejection, so the screen can say "that file is not a pack".
PackArchive decodePackArchive(List<int> bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const PackReject(PackProblem.unreadable, 'zip');
  }

  String? json;
  final photos = <String, List<int>>{};
  for (final entry in archive) {
    if (!entry.isFile) continue;
    if (entry.name == packEntryName) {
      final content = entry.readBytes();
      if (content == null) {
        throw const PackReject(PackProblem.unreadable, 'zip');
      }
      try {
        json = utf8.decode(content);
      } on FormatException {
        throw const PackReject(PackProblem.unreadable, 'pack.json');
      }
      continue;
    }
    if (!entry.name.startsWith(packPhotoPrefix)) continue;
    if (!_isSafeEntry(entry.name)) continue;

    final rest = entry.name.substring(packPhotoPrefix.length);
    final split = rest.indexOf('/');
    // Exactly one folder and one bare file name. Anything deeper is a path this
    // app's own writer never produces.
    if (split <= 0 || rest.indexOf('/', split + 1) >= 0) continue;
    final folder = rest.substring(0, split);
    final fileName = rest.substring(split + 1);
    if (!isStorablePhotoName(fileName)) continue;

    final content = entry.readBytes();
    if (content == null) continue;
    photos['$folder/$fileName'] = content;
  }

  if (json == null) throw const PackReject(PackProblem.notAPack, packEntryName);
  return PackArchive(json: json, photos: photos);
}

/// Only `<prefix><folder>/<file>` with a bare folder name: no absolute path, no
/// `..`, no separators smuggled in.
bool _isSafeEntry(String name) {
  if (!name.startsWith(packPhotoPrefix)) return false;
  if (name.contains('..') || name.contains('\\')) return false;
  if (name.contains('//')) return false;
  final parts = name.substring(packPhotoPrefix.length).split('/');
  return parts.length == 2 && parts.every((part) => part.isNotEmpty);
}

/// The whole backup for this phone: the ledger, and every picture the rows name
/// that this phone still holds.
///
/// A row whose bytes are gone is exported as a row with no picture. That is the
/// honest file: the alternative is refusing to back up a ledger because one
/// image file was deleted outside the app.
Future<Uint8List> buildPackArchive(Database db, PhotoFiles files) async {
  final pack = await packFrom(db);
  final photos = <String, List<int>>{};

  final rows = (pack['rows']! as Map<String, Object?>)['photos'];
  if (rows is List<Object?>) {
    for (final row in rows) {
      if (row is! Map<String, Object?>) continue;
      final animalId = row['animal_id'];
      final fileName = row['file_name'];
      if (animalId is! String || fileName is! String) continue;
      final bytes = await files.readBytes(animalId, fileName);
      if (bytes == null) continue;
      photos['${photoFolder(animalId)}/$fileName'] = bytes;
    }
  }

  return encodePackArchive(encodePack(pack), photos);
}
