import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/photo.dart';
import 'package:salala/presentation/screens/animal_detail_screen.dart';
import 'package:salala/services/photo_files.dart';

import '../helpers/fake_photo_files.dart';
import '../helpers/pump_app.dart';
import '../helpers/section_finder.dart';

const String _nalaId = 'animal-nala';
const String _blank = 'Not on this phone';
const String _empty = 'Nothing recorded yet.';
const String _deleteBody =
    "The picture is removed from this animal's ledger, and the file with it. "
    'This cannot be undone.';

Animal _nala() => Animal(
  id: _nalaId,
  name: 'Nala',
  species: 'dog',
  breed: 'Border collie',
  sex: Sex.female,
  status: AnimalStatus.active,
  isBreedingStock: true,
  birthDate: DateTime(2024, 5, 12).millisecondsSinceEpoch,
  createdAt: 0,
  updatedAt: 0,
);

Photo _picture({String fileName = 'shot.jpg-1024'}) =>
    Photo(id: '', animalId: _nalaId, fileName: fileName, createdAt: 0);

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openNala(WidgetTester tester) async {
  await tester.tap(find.text('Nala'));
  await settleRealIo(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // A row below the fold does not exist yet: the ledger is a lazy list,
  // and the timeline card above the sections moved everything down, so the
  // scroll comes before the `ensureVisible` that used to be enough alone.
  if (finder.evaluate().isEmpty) {
    await _scrollTo(tester, finder);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens the source sheet and picks the gallery, which is what "add a photo"
/// meant before the camera existed.
Future<void> _addFromGallery(WidgetTester tester) async {
  await _tap(tester, find.widgetWithText(TextButton, 'Add photo'));
  await tester.tap(sectionText('Choose from the gallery'));
  await tester.pumpAndSettle();
}

/// Below the weigh-ins, so a test that means the strip has to bring it on stage.
Future<void> _scrollToPhotos(WidgetTester tester) =>
    _scrollTo(tester, sectionText('Photos'));

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.descendant(
      of: find.byType(AnimalDetailScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

/// The picture strip's own emptiness, not the sentence.
///
/// A fresh animal shows `Nothing recorded yet.` in every empty section of its
/// ledger, so the bare text is a count of the sections rather than a statement
/// about the one under test. Scoping to the card titled Photos is what makes
/// `findsOneWidget` mean *this strip*.
Finder _emptyStrip() => find.descendant(
  of: find.widgetWithText(Card, 'Photos'),
  matching: sectionText(_empty),
);

/// A write that goes to the file layer, the database, and then back through the
/// section â€” three round trips, one of them on another isolate.
Future<void> _settleWrite(WidgetTester tester) async {
  await settleRealIo(tester);
  await settleRealIo(tester);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('a picture whose file is not on this phone is a named blank', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(
      tester,
      photoFiles: files,
      seed: <Animal>[_nala()],
      seedPhotos: <Photo>[_picture()],
    );
    await _openNala(tester);
    await _scrollToPhotos(tester);

    expect(sectionText(_blank), findsOneWidget);
    // The name the row carries is the name the screen asked the folder for: this
    // is the one assertion here that the ledger and the file layer are talking
    // about the same picture.
    expect(files.pathsAsked, <String>['$_nalaId/shot.jpg-1024']);
  });

  testWidgets(
    'adding a picture hands the folder and the ledger the same name',
    (tester) async {
      _usePhoneViewport(tester);
      final files = FakePhotoFiles()
        ..nextPicked = FakePhotoFiles.photo('IMG_7.jpg');
      await pumpSalala(tester, photoFiles: files, seed: <Animal>[_nala()]);
      await _openNala(tester);
      await _scrollToPhotos(tester);

      expect(_emptyStrip(), findsOneWidget);

      await _addFromGallery(tester);
      // The tile only exists once the row has landed and the strip has re-read
      // it: waited for by that outcome, because the fixed rounds let this pass
      // alone and fail inside a suite.
      await settleUntil(
        tester,
        () => sectionText(_blank).evaluate().isNotEmpty,
      );

      expect(files.stored, <String>['$_nalaId/IMG_7.jpg-1024']);
      expect(sectionText(_blank), findsOneWidget);
      expect(files.pathsAsked.last, files.stored.first);
    },
  );

  testWidgets('the sheet takes a photo with the camera instead of the gallery', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles()
      ..nextCaptured = FakePhotoFiles.photo('CAM_1.jpg');
    await pumpSalala(tester, photoFiles: files, seed: <Animal>[_nala()]);
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _tap(tester, find.widgetWithText(TextButton, 'Add photo'));
    await tester.tap(sectionText('Take a photo'));
    await tester.pumpAndSettle();

    await settleUntil(tester, () => sectionText(_blank).evaluate().isNotEmpty);

    // The camera is a separate intent from the gallery, and the row proves which
    // one answered: `capture()` was called and `pick()` would have been silent.
    expect(files.captures, 1);
    expect(files.stored, <String>['$_nalaId/CAM_1.jpg-1024']);
  });

  testWidgets('closing the picker writes no row and stores nothing', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(tester, photoFiles: files, seed: <Animal>[_nala()]);
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _addFromGallery(tester);
    await _settleWrite(tester);

    // Backing out of a gallery is a decision, not a failure: nothing is written
    // and nothing is said about it.
    expect(files.stored, isEmpty);
    expect(_emptyStrip(), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'a file that is not a picture is refused before the ledger sees it',
    (tester) async {
      _usePhoneViewport(tester);
      final files = FakePhotoFiles()
        ..nextPicked = FakePhotoFiles.photo('IMG_7.jpg')
        ..storeRefusal = const PhotoRefused(PhotoProblem.notAnImage);
      await pumpSalala(tester, photoFiles: files, seed: <Animal>[_nala()]);
      await _openNala(tester);
      await _scrollToPhotos(tester);

      await _addFromGallery(tester);
      await settleRefusal(tester, waitingFor: 'This file is not a picture');

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: sectionText('This file is not a picture'),
        ),
        findsOneWidget,
      );
      expect(_emptyStrip(), findsOneWidget);
      expect(files.pathsAsked, isEmpty);
    },
  );

  testWidgets('a picture over the cap is refused by size, not by name', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles()
      ..nextPicked = FakePhotoFiles.photo('scan.jpg')
      ..storeRefusal = const PhotoRefused(PhotoProblem.tooLarge);
    await pumpSalala(tester, photoFiles: files, seed: <Animal>[_nala()]);
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _addFromGallery(tester);
    await settleRefusal(tester, waitingFor: 'This picture is too big to keep');

    // Which gate answered, and what a real folder does with 24 MB + 1 byte, is
    // `photo_files_test.dart`'s against a real disk. The screen cannot see either:
    // it is handed one `PhotoProblem` and has to say the size sentence rather than
    // the not-a-picture one, and write nothing.
    expect(_emptyStrip(), findsOneWidget);
    expect(files.stored, isEmpty);
  });

  testWidgets('a row the database refuses takes the stored copy back out', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles()
      ..nextPicked = FakePhotoFiles.photo('IMG_8.jpg');
    await pumpSalala(
      tester,
      photoFiles: files,
      seed: <Animal>[_nala()],
      beforeLaunch: refuseWritesTo('photos'),
    );
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _addFromGallery(tester);
    await settleRefusal(tester, waitingFor: saveRefusalSentence);

    // The copy went in (`stored`), the row did not, and the sentence the screen
    // answers with claims nothing was written. Both halves have to be true of the
    // same picture, or the folder is holding a file no ledger entry can name â€”
    // invisible to the delete that runs off the rows.
    expect(files.stored, hasLength(1));
    expect(files.deleted, files.stored);
    expect(_emptyStrip(), findsOneWidget);
  });

  testWidgets('deleting a picture asks once about the file, then takes both', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(
      tester,
      photoFiles: files,
      seed: <Animal>[_nala()],
      seedPhotos: <Photo>[_picture()],
    );
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _tap(tester, sectionText(_blank));
    expect(find.widgetWithText(TextButton, 'Close'), findsOneWidget);

    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(sectionText('Delete this record?'), findsOneWidget);
    expect(sectionText(_deleteBody), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // Row first, file second, on another isolate: waited for the file call
    // rather than for a count of frames.
    await settleUntil(tester, () => files.deleted.isNotEmpty);

    expect(files.deleted, <String>['$_nalaId/shot.jpg-1024']);
    await _scrollToPhotos(tester);
    // The strip re-reads after the row is gone: one more round trip, so the
    // emptiness is waited for rather than assumed after a frame count.
    await settleUntil(tester, () => _emptyStrip().evaluate().isNotEmpty);
    expect(_emptyStrip(), findsOneWidget);
    expect(sectionText(_blank), findsNothing);
  });

  testWidgets('cancelling the second question takes nothing at all', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(
      tester,
      photoFiles: files,
      seed: <Animal>[_nala()],
      seedPhotos: <Photo>[_picture()],
    );
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _tap(tester, sectionText(_blank));
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    await _tap(tester, find.widgetWithText(TextButton, 'Cancel'));

    expect(files.deleted, isEmpty);
    expect(sectionText(_blank), findsOneWidget);
  });

  testWidgets('a picture the database refuses to delete stays on the strip', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(
      tester,
      photoFiles: files,
      seed: <Animal>[_nala()],
      seedPhotos: <Photo>[_picture()],
      beforeLaunch: refuseDeletesOf('photos'),
    );
    await _openNala(tester);
    await _scrollToPhotos(tester);

    await _tap(tester, sectionText(_blank));
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleRefusal(tester, waitingFor: deleteRefusalSentence);

    // Row first, file second: SQLite said no, so the bytes are exactly where they
    // were and the strip still shows the picture the breeder did not lose.
    expect(files.deleted, isEmpty);
    expect(sectionText(_blank), findsOneWidget);
  });

  testWidgets(
    "a file that outlives its row is the folder's problem, not the screen's",
    (tester) async {
      _usePhoneViewport(tester);
      final files = FakePhotoFiles()..deleteFailure = StateError('locked');
      await pumpSalala(
        tester,
        photoFiles: files,
        seed: <Animal>[_nala()],
        seedPhotos: <Photo>[_picture()],
      );
      await _openNala(tester);
      await _scrollToPhotos(tester);

      await _tap(tester, sectionText(_blank));
      await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      // The row goes, the file delete fails, and the strip reloads: three
      // round trips, one of them on another isolate. Waited for by its outcome,
      // because a fixed count of frames is what let this pass alone and fail in
      // a suite.
      await settleUntil(tester, () => _emptyStrip().evaluate().isNotEmpty);

      // The ledger is already right â€” the row is gone â€” and the leftover is swept
      // by the folder clear that follows the animal itself. A stray file is not a
      // sentence worth interrupting a person with, so nothing is claimed either way.
      expect(_emptyStrip(), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('deleting the animal takes its picture folder with it', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(
      tester,
      photoFiles: files,
      seed: <Animal>[_nala()],
      seedPhotos: <Photo>[_picture()],
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(sectionText('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // The folder is cleared inside the delete, before the list is re-read, so
    // this waits on that call rather than on a frame count â€” and then on the
    // list actually losing the row, which is the second round trip.
    await settleUntil(tester, () => files.clearedFolders.isNotEmpty);
    await settleUntil(tester, () => sectionText('Nala').evaluate().isEmpty);

    // The rows go with the animal in SQLite; only this app can reach the folder.
    expect(files.clearedFolders, <String>[_nalaId]);
    expect(sectionText('Nala'), findsNothing);
  });

  testWidgets('an animal with no rows still loses the picture folder', (
    tester,
  ) async {
    // The corner the row count cannot see: a copy whose insert was refused, whose
    // sweep then failed too, leaves bytes the ledger has never heard of. Clearing
    // the folder only when rows exist would keep a dead animal's photograph on
    // the phone with no row, no screen and no way to find it â€” so the promise is
    // the folder going, and this test is what that choice costs in calls.
    _usePhoneViewport(tester);
    final files = FakePhotoFiles();
    await pumpSalala(tester, photoFiles: files, seed: <Animal>[_nala()]);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(sectionText('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleUntil(tester, () => files.clearedFolders.isNotEmpty);

    expect(files.clearedFolders, <String>[_nalaId]);
  });

  testWidgets('the Arabic ledger names the picture strip and its blank', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await pumpSalala(
      tester,
      locale: const Locale('ar'),
      seed: <Animal>[_nala()],
      seedPhotos: <Photo>[_picture()],
    );
    await _openNala(tester);
    await _scrollTo(tester, sectionText('الصور'));

    expect(sectionText('الصور'), findsOneWidget);
    expect(sectionText('ليست على هذا الهاتف'), findsOneWidget);
  });
}
