import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A pack's trip to and from the phone's files, behind one seam.
///
/// What goes *into* a pack is decided and tested against a real database in
/// `data_pack.dart` and `animal_pdf.dart`. This file only moves bytes, which is
/// the part that needs a phone — so the screens above it can be tested with a
/// recorder here.
abstract class PackFiles {
  const PackFiles();

  /// Writes the bytes where the share sheet can reach them and opens the sheet.
  /// Returns the file name, which is what the breeder is told to look for.
  Future<String> shareBytes(String name, List<int> bytes);

  /// The text of a file the breeder chose, or null if they backed out.
  Future<String?> pick();
}

class SystemPackFiles extends PackFiles {
  const SystemPackFiles();

  @override
  Future<String> shareBytes(String name, List<int> bytes) async {
    // `share_plus` publishes only its own `cache/share_plus` folder through a
    // FileProvider, so a file anywhere else cannot be granted to another app.
    // The pack goes where the sheet is allowed to reach, not where it is tidy.
    final cache = await getApplicationCacheDirectory();
    final folder = Directory(p.join(cache.path, 'share_plus'));
    await folder.create(recursive: true);
    final file = File(p.join(folder.path, name));
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path)]),
    );
    return name;
  }

  @override
  Future<String?> pick() async {
    // No type filter on purpose. A pack that was renamed, emailed, or put on a
    // USB stick arrives as text/plain or with no type at all, and a filter that
    // hides the file reads as the app refusing the backup.
    final XFile? file = await openFile();
    if (file == null) return null;
    return file.readAsString();
  }
}

/// `20261005-2041`, so two exports on one day do not overwrite each other.
String fileStamp(DateTime at) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}';
}

String packFileName(DateTime now) => 'salala-pack-${fileStamp(now)}.json';

/// `salala-nala-20261005-2041.pdf`, named for the animal it describes.
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
      ? 'salala-${fileStamp(now)}.pdf'
      : 'salala-$slug-${fileStamp(now)}.pdf';
}
