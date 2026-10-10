import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/photo.dart';

import '../../helpers/test_db.dart';

void main() {
  group('PhotoDao', () {
    late Daos daos;
    late String animalId;

    setUp(() async {
      final db = await openTestDatabase();
      daos = Daos(db);
      addTearDown(db.close);

      final animal = await daos.animals.create(
        Animal(
          id: '',
          name: 'Zida',
          species: 'dog',
          sex: Sex.female,
          status: AnimalStatus.active,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 1,
      );
      animalId = animal.id;
    });

    Photo picture({String fileName = '1-100.jpg', int takenAt = 0}) => Photo(
      id: '',
      animalId: animalId,
      fileName: fileName,
      createdAt: takenAt,
    );

    test(
      'round-trips a row and gives it the id and date the ledger stores',
      () async {
        final created = await daos.photos.create(picture(), nowMs: 500);

        expect(created.id, isNotEmpty);
        expect(created.createdAt, 500);
        expect(await daos.photos.findById(created.id), created);
      },
    );

    test('lists one animal oldest picture first', () async {
      await daos.photos.create(picture(fileName: 'second.jpg'), nowMs: 20);
      await daos.photos.create(picture(fileName: 'first.jpg'), nowMs: 10);
      await daos.photos.create(picture(fileName: 'third.jpg'), nowMs: 30);

      final rows = await daos.photos.forAnimal(animalId);
      expect(rows.map((row) => row.fileName).toList(), <String>[
        'first.jpg',
        'second.jpg',
        'third.jpg',
      ]);
    });

    test('an animal is the only owner of its pictures', () async {
      final created = await daos.photos.create(picture(), nowMs: 5);
      await expectLater(
        daos.photos.create(
          Photo(
            id: '',
            animalId: 'nobody',
            fileName: 'orphan.jpg',
            createdAt: 0,
          ),
        ),
        throwsA(anything),
      );

      // The one that landed is reachable from its own animal and from nowhere
      // else: `forAnimal` is how the delete that takes the animal finds the files.
      expect(await daos.photos.forAnimal(animalId), <Photo>[created]);
      expect(await daos.photos.forAnimal('nobody'), isEmpty);
    });

    test('deleting the animal takes its picture rows with it', () async {
      await daos.photos.create(picture(fileName: 'a.jpg'), nowMs: 1);
      await daos.photos.create(picture(fileName: 'b.jpg'), nowMs: 2);

      await daos.animals.delete(animalId);

      expect(await daos.photos.forAnimal(animalId), isEmpty);
    });
  });
}
