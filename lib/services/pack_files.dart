import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A pack the breeder chose: the file's name for the log, and its bytes.
///
/// Bytes rather than text because a backup is a ZIP now (rows and pictures), and
/// a reader that decoded every file as a string would turn a JPEG into mojibake
/// before it ever reached the archive. Which shape the file is, is decided by
/// its first four bytes, not by its name — a breeder may have renamed it.
class PickedPackFile {
  const PickedPackFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// A pack's trip to and from the phone's files, behind one seam.
///
/// What goes *into* a pack is decided and tested against a real database in
/// `data_pack.dart`, `pack_archive.dart` and `animal_pdf.dart`. This file only
/// moves bytes, which is the part that needs a phone — so the screens above it
/// can be tested with a recorder here.
abstract class PackFiles {
  const PackFiles();

  /// Writes the bytes where the share sheet can reach them and opens the sheet.
  /// Returns the file name, which is what the breeder is told to look for.
  Future<String> shareBytes(String name, List<int> bytes);

  /// The file the breeder chose, or null if they backed out.
  Future<PickedPackFile?> pick();
}

class SystemPackFiles extends PackFiles {
  const SystemPackFiles();

  @override
  Future<String> shareBytes(String name, List<int> bytes) async {
    // Not `cache/share_plus`: that is the plugin's own scratch folder, which it
    // empties as the first act of every share and then refuses to read from. A
    // pack written there was deleted before the sheet opened — measured on the
    // phone, where export failed with "Shared file can not be located in
    // '.../cache/share_plus'". Any other folder works: the plugin copies the
    // file into its own and publishes that copy through its FileProvider.
    final cache = await getApplicationCacheDirectory();
    final folder = Directory(p.join(cache.path, 'companion_out'));
    await folder.create(recursive: true);
    final file = File(p.join(folder.path, name));
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path)]),
    );
    return name;
  }

  @override
  Future<PickedPackFile?> pick() async {
    // No type filter on purpose. A pack that was renamed, emailed, or put on a
    // USB stick arrives as text/plain or with no type at all, and a filter that
    // hides the file reads as the app refusing the backup.
    final XFile? file = await openFile();
    if (file == null) return null;
    return PickedPackFile(name: file.name, bytes: await file.readAsBytes());
  }
}

/// `20261005-2041`, so two exports on one day do not overwrite each other.
String fileStamp(DateTime at) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}';
}

/// `companion-pack-20261005-2041.zip`: the ledger and its pictures.
///
/// `.zip` rather than `.json` because the file is a container now. A breeder who
/// renames it can still restore it — the reader sniffs the bytes — but the name
/// is what mail apps and file managers use to offer the right thing.
String packFileName(DateTime now) => 'companion-pack-${fileStamp(now)}.zip';

/// `companion-herd-20261005-2041.csv`, and the three siblings below.
///
/// Slugged to plain ASCII for the same reason the PDF is: the name is what lands
/// in a Downloads folder and inside a mail attachment list, and a CSV whose name
/// only renders on the phone that made it is a CSV the accountant cannot find.
/// The table's own name goes in the file, not a translated word, so one export
/// from an Arabic phone and one from a French phone compare row for row.
String csvFileName(String table, DateTime now) =>
    'companion-$table-${fileStamp(now)}.csv';

/// `companion-nala-20261005-2041.pdf`, named for the animal it describes.
///
/// The name is slugged to plain ASCII because this string is what lands in a
/// buyer's Downloads folder: an animal called `نالة / 2026` would otherwise
/// produce a file no filesystem or mail app agrees about. A wholly non-Latin
/// name slugs away to nothing, and the timestamp alone is still a usable file.
String pdfFileName(String animalName, DateTime now) {
  final slug = animalName
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '')
      .toLowerCase();
  return slug.isEmpty
      ? 'companion-${fileStamp(now)}.pdf'
      : 'companion-$slug-${fileStamp(now)}.pdf';
}
