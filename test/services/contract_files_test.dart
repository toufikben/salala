import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:companion/services/contract_files.dart';
import 'package:companion/services/photo_files.dart' show photoFolder;

/// The contract layer against a real folder on a real disk.
///
/// Same reasoning as `photo_files_test.dart`: `SystemContractFiles` takes its
/// root as an injection so that what is checked is the real `dart:io` behaviour
/// rather than a fake that could agree with a bug in the rules.
///
/// A contract is the one file this app stores that carries a second person's
/// signature, so the two promises worth a test are the ones a privacy claim rests
/// on: the bytes live under this app's own folder, and a row can only ever name a
/// bare file inside it.
void main() {
  late Directory root;

  SystemContractFiles files() =>
      SystemContractFiles(directory: () async => root.path);

  PickedContract picked(String name, {int bytes = 8}) =>
      PickedContract(name: name, bytes: Uint8List(bytes));

  setUp(() async {
    root = await Directory.systemTemp.createTemp('companion_contracts_test_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
  });

  group('isStorableContractName', () {
    test('a bare name is storable', () {
      for (final good in <String>[
        '1729000000000-20480.pdf',
        'a-b_c.1.pdf',
        'with space.pdf',
        'contract',
      ]) {
        expect(isStorableContractName(good), isTrue, reason: good);
      }
    });

    test('a path, a parent hop or a blank is not', () {
      for (final bad in <String>[
        '../escape.pdf',
        'a/b.pdf',
        r'win\dows.pdf',
        '..',
        '',
        ' leading.pdf',
        '.hidden.pdf',
      ]) {
        expect(isStorableContractName(bad), isFalse, reason: bad);
      }
    });
  });

  group('store', () {
    test('writes the bytes under the app folder, named by time and size', () async {
      final name = await files().store('animal-1', picked('Scan.PDF', bytes: 12));

      // Not the source name: two contracts may both be called `contract.pdf`.
      expect(name, isNot(contains('Scan')));
      expect(name, endsWith('.pdf'));
      expect(isStorableContractName(name), isTrue);

      final written = File(
        p.join(root.path, contractsDirectoryName, photoFolder('animal-1'), name),
      );
      expect(await written.exists(), isTrue);
      expect(await written.length(), 12);
    });

    test('two files with one name do not overwrite each other', () async {
      final files_ = files();
      final first = await files_.store('animal-1', picked('contract.pdf'));
      final second = await files_.store('animal-1', picked('contract.pdf'));

      expect(first, isNot(second));
      final folder = Directory(
        p.join(root.path, contractsDirectoryName, photoFolder('animal-1')),
      );
      expect(folder.listSync().length, 2);
    });

    test('an extension with punctuation in it is not carried into the name', () async {
      final name = await files().store('animal-1', picked('scan.<b>.pdf'));

      expect(name, endsWith('.pdf'));
      expect(name, isNot(contains('<')));
    });

    test('a file past the limit is refused and nothing is written', () async {
      final tooBig = PickedContract(
        name: 'huge.pdf',
        bytes: Uint8List(maxContractBytes + 1),
      );

      await expectLater(
        files().store('animal-1', tooBig),
        throwsA(
          isA<ContractRefused>().having(
            (refused) => refused.problem,
            'problem',
            ContractProblem.tooLarge,
          ),
        ),
      );
      final folder = Directory(
        p.join(root.path, contractsDirectoryName, photoFolder('animal-1')),
      );
      expect(folder.existsSync(), isFalse);
    });

    test('an unwanted animal id cannot climb out of the folder', () async {
      final name = await files().store('../../etc', picked('a.pdf'));
      final written = File(
        p.join(root.path, contractsDirectoryName, photoFolder('../../etc'), name),
      );

      expect(await written.exists(), isTrue);
      // Straight up, not up and out.
      expect(p.isWithin(root.path, written.path), isTrue);
    });
  });

  group('pathFor', () {
    test('answers the path of a file that is there', () async {
      final files_ = files();
      final name = await files_.store('animal-1', picked('a.pdf'));
      final path = await files_.pathFor('animal-1', name);

      expect(path, isNotNull);
      expect(await File(path!).exists(), isTrue);
    });

    test('answers null for a name the folder does not hold', () async {
      expect(await files().pathFor('animal-1', '1700000000000-1.pdf'), isNull);
    });

    test('answers null rather than opening a path a row was edited to hold', () async {
      // A row restored from a pack written by an older build could name an
      // absolute path from the phone that made it. It resolves to nothing.
      for (final bad in <String>['/etc/passwd', r'C:\Windows\win.ini', '../x.pdf']) {
        expect(await files().pathFor('animal-1', bad), isNull, reason: bad);
      }
    });
  });

  group('readBytes', () {
    test('answers the bytes of a file that is there', () async {
      final files_ = files();
      final name = await files_.store(
        'animal-1',
        PickedContract(name: 'a.pdf', bytes: Uint8List.fromList(<int>[7, 8, 9])),
      );

      expect(await files_.readBytes('animal-1', name), <int>[7, 8, 9]);
    });

    test('answers null for a name the folder does not hold', () async {
      expect(await files().readBytes('animal-1', '1700000000000-1.pdf'), isNull);
    });

    test('answers null rather than reading a path a row was edited to hold', () async {
      final outside = File(p.join(root.path, 'outside.pdf'));
      await outside.writeAsBytes(<int>[1, 2, 3]);

      for (final bad in <String>['../outside.pdf', '/etc/passwd']) {
        expect(await files().readBytes('animal-1', bad), isNull, reason: bad);
      }
    });
  });

  group('delete', () {
    test('removes one contract and leaves its neighbour', () async {
      final files_ = files();
      final keep = await files_.store('animal-1', picked('keep.pdf'));
      final drop = await files_.store('animal-1', picked('drop.pdf'));

      await files_.delete('animal-1', drop);

      expect(await files_.pathFor('animal-1', drop), isNull);
      expect(await files_.pathFor('animal-1', keep), isNotNull);
    });

    // The neighbour above only survives because two stores usually land in
    // different milliseconds. Two documents of the same size stored in the same
    // millisecond — a signed contract and the scan of it — used to produce one
    // name, and the second write silently replaced the first. The name is now
    // issued by a counter, so this case cannot come back without this test
    // failing.
    test('two stores in one millisecond and one size keep both files', () async {
      final files_ = files();
      final first = await files_.store('animal-1', picked('a.pdf', bytes: 8));
      final second = await files_.store('animal-1', picked('b.pdf', bytes: 8));

      expect(first, isNot(second));
      final folder = Directory(
        p.join(root.path, contractsDirectoryName, photoFolder('animal-1')),
      );
      expect(folder.listSync().length, 2);
      expect(await files_.pathFor('animal-1', first), isNotNull);
      expect(await files_.pathFor('animal-1', second), isNotNull);
    });

    test('deleting a file that is not there is not an error', () async {
      await expectLater(
        files().delete('animal-1', '1700000000000-1.pdf'),
        completes,
      );
    });

    test('a name that is not a bare name is refused before it is a path', () async {
      final outside = File(p.join(root.path, 'outside.pdf'));
      await outside.writeAsBytes(<int>[1, 2, 3]);

      await files().delete('animal-1', '../outside.pdf');

      expect(await outside.exists(), isTrue);
    });

    test('deleteAll takes the animal folder and leaves the others', () async {
      final files_ = files();
      await files_.store('animal-1', picked('a.pdf'));
      await files_.store('animal-2', picked('b.pdf'));

      await files_.deleteAll('animal-1');

      final gone = Directory(
        p.join(root.path, contractsDirectoryName, photoFolder('animal-1')),
      );
      final here = Directory(
        p.join(root.path, contractsDirectoryName, photoFolder('animal-2')),
      );
      expect(gone.existsSync(), isFalse);
      expect(here.existsSync(), isTrue);
    });

    test('deleteAll on an animal with nothing attached is not an error', () async {
      await expectLater(files().deleteAll('animal-9'), completes);
    });
  });
}
