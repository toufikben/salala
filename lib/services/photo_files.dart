import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A picture the breeder chose, before this app owns a copy of it.
class PickedPhoto {
  const PickedPhoto({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get length => bytes.length;
}

/// A picture refused on the way in, with the sentence the screen shows.
enum PhotoProblem {
  /// Bigger than [maxPhotoBytes]. A 60 MB raw is not a ledger attachment.
  tooLarge,

  /// Not a file type this app will store.
  notAnImage,
}

class PhotoRefused implements Exception {
  const PhotoRefused(this.problem, [this.detail = '']);

  final PhotoProblem problem;
  final String detail;

  @override
  String toString() =>
      'PhotoRefused(${problem.name}${detail.isEmpty ? '' : ', $detail'})';
}

/// A refused file is still a file the breeder can see, so the cap is generous:
/// a 12-megapixel phone JPEG is 3-6 MB, and a lossless screenshot is a few more.
const int maxPhotoBytes = 24 * 1024 * 1024;

/// The extensions this app will store and render. A picker is not a gate —
/// `file_selector` on a desktop host lets anything through — so the name is
/// checked here as well.
///
/// HEIC is deliberately absent, not overlooked: the Flutter engine has no HEIF
/// decoder, so a stored `.heic` row is a picture this app can never draw — the
/// permanent blank the ledger has no use for. Android's own gallery tools hand
/// back a JPEG when a HEIF is opened through the picker anyway, so nothing the
/// breeder means is lost by refusing the container here.
const List<String> photoExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'webp',
  'gif',
];

/// Where a picture lives, and how it gets there — behind one seam.
///
/// `data_pack.dart` decides what a backup holds and proves it against a real
/// database; this is the part that needs a filesystem, so the screens above it
/// run against a recorder. The rule the whole class rests on: a `photos` row
/// holds a bare file name, and the bytes live under one folder per animal, so
/// nothing a row says can point outside the folder this app owns.
abstract class PhotoFiles {
  const PhotoFiles();

  /// The image the breeder chose, or null if they backed out.
  Future<PickedPhoto?> pick();

  /// Copies [photo] into the animal's folder and returns the bare file name to
  /// store on the row. Throws [PhotoRefused] for a file this app will not keep.
  Future<String> store(String animalId, PickedPhoto photo);

  /// Removes one picture. A missing file is not an error: the row is going away
  /// either way, and a pack restored on a second phone has rows with no bytes.
  Future<void> delete(String animalId, String fileName);

  /// Removes every picture of one animal, for the delete that takes the animal
  /// itself with it.
  Future<void> deleteAll(String animalId);

  /// The path to render, or null when the bytes are not on this phone.
  Future<String?> pathFor(String animalId, String fileName);
}

/// `photos/<animal id>/`. The id is sanitised rather than trusted: it reaches a
/// folder name from a JSON pack someone else could have written.
String photoFolder(String animalId) {
  final safe = animalId
      .replaceAll(RegExp('[^A-Za-z0-9_-]'), '_')
      .replaceAll(RegExp('_+'), '_');
  return safe.isEmpty ? '_' : safe;
}

/// A file name a row is allowed to point at: one bare name, no separators, no
/// parent hops. Anything else is refused *as a name*, which renders the picture
/// as missing instead of opening a file outside the folder.
bool isStorablePhotoName(String fileName) =>
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9._ -]{0,119}$').hasMatch(fileName) &&
    !fileName.contains('..');

String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

class SystemPhotoFiles extends PhotoFiles {
  /// Overridable so the file rules are testable on a host without a phone;
  /// production uses the app's own documents directory.
  /// Overridable so the file rules are testable on a host without a phone;
  /// production uses the app's own documents directory.
  const SystemPhotoFiles({this.directory});

  final Future<String> Function()? directory;

  Future<String> get _root async {
    final base = await (directory ?? _documents)();
    return p.join(base, 'photos');
  }

  static Future<String> _documents() async =>
      (await getApplicationDocumentsDirectory()).path;

  Future<String> _folder(String animalId) async =>
      p.join(await _root, photoFolder(animalId));

  @override
  Future<PickedPhoto?> pick() async {
    // Images only. Unlike a pack, a photo has a type the picker can honour:
    // nothing a breeder means here is a text file renamed to look like one.
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(label: 'Photos', extensions: photoExtensions),
      ],
    );
    if (file == null) return null;
    return PickedPhoto(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<String> store(String animalId, PickedPhoto photo) async {
    final extension = _extensionOf(photo.name);
    if (!photoExtensions.contains(extension)) {
      throw const PhotoRefused(PhotoProblem.notAnImage);
    }
    if (photo.length > maxPhotoBytes) {
      throw PhotoRefused(PhotoProblem.tooLarge, '${photo.length}');
    }
    final folder = await _folder(animalId);
    await Directory(folder).create(recursive: true);
    // Named here rather than kept from the source: a gallery file is called
    // IMG_2841.jpg on the second animal too, and two animals may own that name.
    // The extension is the only part of the old name worth carrying.
    final name =
        '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${photo.bytes.length}.$extension';
    if (!isStorablePhotoName(name)) {
      throw PhotoRefused(PhotoProblem.notAnImage, name);
    }
    await File(p.join(folder, name)).writeAsBytes(photo.bytes, flush: true);
    return name;
  }

  @override
  Future<void> delete(String animalId, String fileName) async {
    if (!isStorablePhotoName(fileName)) return;
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
    if (!isStorablePhotoName(fileName)) return null;
    final file = File(p.join(await _folder(animalId), fileName));
    return await file.exists() ? file.path : null;
  }
}
