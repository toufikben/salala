import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:salala/services/photo_files.dart';

/// The file layer against a real folder on a real disk.
///
/// `SystemPhotoFiles` takes its root as an injection for exactly this: no plugin
/// channel, no phone, and no fake that could quietly agree with a bug in the
/// rules. What is checked here is the pair of promises the ledger rests on — a
/// row names one bare file inside one folder this app owns, and nothing a row
/// says can point anywhere else.
void main() {
  late Directory root;

  String animalId(String name) => 'animal-$name';

  SystemPhotoFiles files() =>
      SystemPhotoFiles(directory: () async => root.path);

  PickedPhoto picked(String name, {int bytes = 8}) =>
      PickedPhoto(name: name, bytes: Uint8List(bytes));

  setUp(() async {
    root = await Directory.systemTemp.createTemp('salala_photos_test_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
  });

  group('the folder a row may name', () {
    test('an animal id is made safe before it becomes a path segment', () {
      // Ids are uuids from this app, but a pack is JSON someone can edit, and
      // `photoFolder` is where that string meets the filesystem.
      for (final raw in <String>[
        '../../etc',
        'a/b',
        r'win\dows\path',
        '..\\..\\escape',
        '',
        ' ',
      ]) {
        final folder = photoFolder(raw);
        expect(folder, isNot(contains('/')));
        expect(folder, isNot(contains(r'\')));
        expect(folder, isNot(contains('..')));
        expect(folder, isNotEmpty);
      }
    });

    test('only a bare file name is ever storable', () {
      for (final good in <String>[
        '1729000000000-20480.jpg',
        'a-b_c.1.png',
        'with space.jpg',
      ]) {
        expect(isStorablePhotoName(good), isTrue, reason: good);
      }
      for (final bad in <String>[
        '',
        '../outside.jpg',
        'a/b.jpg',
        '/etc/passwd',
        r'..\..\x.jpg',
        '.hidden.jpg',
        'x' * 121,
      ]) {
        expect(isStorablePhotoName(bad), isFalse, reason: bad);
      }
    });
  });

  group('SystemPhotoFiles', () {
    test(
      'stores the bytes under the animal folder and returns the bare name',
      () async {
        final id = animalId('nala');
        final fileName = await files().store(
          id,
          picked('IMG_2841.JPG', bytes: 12),
        );

        expect(isStorablePhotoName(fileName), isTrue);
        expect(
          fileName.endsWith('.jpg'),
          isTrue,
          reason: 'the case is lowered',
        );

        final written = File(
          p.join(root.path, 'photos', photoFolder(id), fileName),
        );
        expect(written.existsSync(), isTrue);
        expect(written.readAsBytesSync(), hasLength(12));
      },
    );

    test('two animals may own the same gallery file name', () async {
      final first = await files().store(animalId('a'), picked('IMG_1.jpg'));
      final second = await files().store(animalId('b'), picked('IMG_1.jpg'));

      // One folder each, so neither overwrites the other and neither can read
      // the other's picture by guessing a name.
      expect(
        File(p.join(root.path, 'photos', 'animal-a', first)).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, 'photos', 'animal-b', second)).existsSync(),
        isTrue,
      );
    });

    test('a file that is not a picture never reaches the folder', () async {
      for (final name in <String>[
        'notes.txt',
        // Not a text file renamed: a real iPhone container this app cannot
        // decode, so storing it would write a row whose picture never appears.
        'IMG_0042.heic',
      ]) {
        await expectLater(
          files().store(animalId('a'), picked(name)),
          throwsA(
            isA<PhotoRefused>().having(
              (e) => e.problem,
              'problem',
              PhotoProblem.notAnImage,
            ),
          ),
          reason: name,
        );
      }
      expect(
        Directory(p.join(root.path, 'photos')).existsSync(),
        isFalse,
        reason: 'refused means no folder and no file, nothing to clean up',
      );
    });

    test('a picture over the cap is refused by size, not by name', () async {
      await expectLater(
        files().store(
          animalId('a'),
          picked('huge.jpg', bytes: maxPhotoBytes + 1),
        ),
        throwsA(
          isA<PhotoRefused>().having(
            (e) => e.problem,
            'problem',
            PhotoProblem.tooLarge,
          ),
        ),
      );
      expect(Directory(p.join(root.path, 'photos')).existsSync(), isFalse);
    });

    test(
      'a path comes back for a file that is there and none for one that is not',
      () async {
        final id = animalId('a');
        final fileName = await files().store(id, picked('one.jpg'));

        expect(await files().pathFor(id, fileName), isNotNull);
        expect(await files().pathFor(id, 'missing.jpg'), isNull);
        // A different animal's file is not this one's to render, even by name.
        final other = await files().store(animalId('b'), picked('two.jpg'));
        expect(await files().pathFor(id, other), isNull);
      },
    );

    test(
      'a name a hand-written pack invented is answered with nothing',
      () async {
        final escape = p.join(root.path, 'outside.jpg');
        File(escape).writeAsBytesSync(<int>[1, 2, 3]);

        expect(await files().pathFor(animalId('a'), '../outside.jpg'), isNull);
        await expectLater(
          files().delete(animalId('a'), '../outside.jpg'),
          completes,
        );
        expect(
          File(escape).existsSync(),
          isTrue,
          reason:
              'a delete that honoured that name would have removed a file '
              'outside the folder, which is the one thing the row must not be able to ask for',
        );
      },
    );

    test(
      'delete takes the file and tolerates one that is already gone',
      () async {
        final id = animalId('a');
        final fileName = await files().store(id, picked('one.jpg'));
        final path = (await files().pathFor(id, fileName))!;

        await files().delete(id, fileName);
        expect(File(path).existsSync(), isFalse);
        await expectLater(files().delete(id, fileName), completes);
      },
    );

    test('deleteAll takes the folder with everything in it', () async {
      final id = animalId('a');
      await files().store(id, picked('one.jpg'));
      await files().store(id, picked('two.jpg'));
      final folder = Directory(p.join(root.path, 'photos', photoFolder(id)));
      expect(folder.existsSync(), isTrue);

      await files().deleteAll(id);
      expect(folder.existsSync(), isFalse);
      await expectLater(files().deleteAll(id), completes);
    });
  });
}
