import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/litter.dart';

import '../../helpers/test_db.dart';

Animal _animal({
  String id = '',
  required String name,
  String species = 'dog',
  int? birthDate,
  bool breeding = false,
  String? litterId,
}) {
  return Animal(
    id: id,
    name: name,
    species: species,
    sex: Sex.unknown,
    status: AnimalStatus.active,
    birthDate: birthDate,
    isBreedingStock: breeding,
    litterId: litterId,
    createdAt: 0,
    updatedAt: 0,
  );
}

void main() {
  late Daos daos;

  setUp(() async {
    final db = await openTestDatabase();
    daos = Daos(db);
    addTearDown(db.close);
  });

  group('AnimalDao', () {
    test('create assigns an id and the timestamps', () async {
      final created = await daos.animals.create(
        _animal(name: 'Atlas'),
        nowMs: 500,
      );

      expect(created.id, isNotEmpty);
      expect(created.createdAt, 500);
      expect(created.updatedAt, 500);

      final readBack = await daos.animals.findById(created.id);
      expect(readBack, created);
    });

    test('create keeps an id it was given (import path)', () async {
      final created = await daos.animals.create(
        _animal(id: 'fixed-1', name: 'Elsa'),
        nowMs: 1,
      );
      expect(created.id, 'fixed-1');
    });

    test('update writes the new values and bumps updated_at', () async {
      final created = await daos.animals.create(
        _animal(name: 'Nala'),
        nowMs: 10,
      );
      await daos.animals.update(
        created.copyWith(name: 'Nala II', isBreedingStock: true),
        nowMs: 20,
      );

      final readBack = await daos.animals.findById(created.id);
      expect(readBack, isNotNull);
      expect(readBack!.name, 'Nala II');
      expect(readBack.isBreedingStock, isTrue);
      expect(readBack.updatedAt, 20);
      expect(
        readBack.createdAt,
        10,
        reason: 'created_at must survive an update',
      );
    });

    test(
      'findAll orders animals with a known birth date first, newest first',
      () async {
        await daos.animals.create(
          _animal(name: 'Old', birthDate: 1000),
          nowMs: 1,
        );
        await daos.animals.create(_animal(name: 'Unknown'), nowMs: 2);
        await daos.animals.create(
          _animal(name: 'New', birthDate: 3000),
          nowMs: 3,
        );

        final all = await daos.animals.findAll();
        expect(all.map((a) => a.name).toList(), <String>[
          'New',
          'Old',
          'Unknown',
        ]);
      },
    );

    test('findAll filters by species and status', () async {
      await daos.animals.create(_animal(name: 'Rex', species: 'dog'), nowMs: 1);
      await daos.animals.create(
        _animal(name: 'Mimi', species: 'cat'),
        nowMs: 2,
      );

      expect((await daos.animals.findAll(species: 'cat')).single.name, 'Mimi');
      expect(await daos.animals.findAll(status: AnimalStatus.sold), isEmpty);
    });

    test(
      'findBreedingStock and findOffspring use the indexed columns',
      () async {
        final dam = await daos.animals.create(
          _animal(name: 'Dam', breeding: true),
          nowMs: 1,
        );
        // The litter row must exist first: animals.litter_id is a real FK.
        await daos.litters.create(
          Litter(
            id: 'L1',
            name: 'L1',
            damId: dam.id,
            createdAt: 1,
            updatedAt: 1,
          ),
          nowMs: 1,
        );
        await daos.animals.create(
          _animal(name: 'Pup B', litterId: 'L1'),
          nowMs: 2,
        );
        await daos.animals.create(
          _animal(name: 'Pup A', litterId: 'L1'),
          nowMs: 3,
        );

        expect((await daos.animals.findBreedingStock()).single.id, dam.id);
        expect(
          (await daos.animals.findOffspring('L1')).map((a) => a.name).toList(),
          <String>['Pup A', 'Pup B'],
        );
      },
    );

    test('delete removes the animal and cascades to its litter', () async {
      final dam = await daos.animals.create(_animal(name: 'Dam'), nowMs: 1);
      final litter = await daos.litters.create(
        Litter(id: '', name: 'L1', damId: dam.id, createdAt: 0, updatedAt: 0),
        nowMs: 1,
      );
      expect(await daos.litters.findById(litter.id), isNotNull);

      await daos.animals.delete(dam.id);
      expect(await daos.litters.findById(litter.id), isNull);
    });

    test('distinctSpecies and count answer the home screen', () async {
      await daos.animals.create(_animal(name: 'a', species: 'dog'), nowMs: 1);
      await daos.animals.create(_animal(name: 'b', species: 'cat'), nowMs: 2);
      await daos.animals.create(_animal(name: 'c', species: 'dog'), nowMs: 3);

      expect(await daos.animals.distinctSpecies(), <String>['cat', 'dog']);
      expect(await daos.animals.count(), 3);
    });
  });
}
