import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/litter.dart';

import '../../helpers/test_db.dart';

Animal _animal({
  String id = '',
  required String name,
  Sex sex = Sex.unknown,
  bool breeding = false,
}) {
  return Animal(
    id: id,
    name: name,
    species: 'dog',
    breed: 'Border collie',
    sex: sex,
    status: AnimalStatus.active,
    isBreedingStock: breeding,
    createdAt: 0,
    updatedAt: 0,
  );
}

Litter _litter({
  required String damId,
  String? sireId,
  String name = 'A litter',
}) {
  return Litter(
    id: '',
    name: name,
    damId: damId,
    sireId: sireId,
    matingDate: 100,
    whelpingDate: 200,
    weaningDate: null,
    notes: '',
    createdAt: 0,
    updatedAt: 0,
  );
}

Animal _puppy(String name) => _animal(id: '', name: name);

void main() {
  late Daos daos;

  setUp(() async {
    daos = Daos(await openTestDatabase());
  });

  group('LitterDao.createWithPuppies', () {
    test('writes the litter and stamps every puppy with it and both parents', () async {
      final dam = await daos.animals.create(
        _animal(name: 'Nala', sex: Sex.female, breeding: true),
        nowMs: 1,
      );
      final sire = await daos.animals.create(
        _animal(name: 'Atlas', sex: Sex.male, breeding: true),
        nowMs: 2,
      );

      final created = await daos.litters.createWithPuppies(
        _litter(damId: dam.id, sireId: sire.id),
        <Animal>[_puppy('A litter 1'), _puppy('A litter 2')],
        nowMs: 10,
      );

      expect(created.id, isNotEmpty);
      expect(created.createdAt, 10);

      final puppies = await daos.animals.findOffspring(created.id);
      expect(puppies.map((p) => p.name), <String>['A litter 1', 'A litter 2']);
      for (final puppy in puppies) {
        // The caller left these blank: the dao is what makes a puppy belong to
        // its whelping, so no screen can register one that disagrees.
        expect(puppy.damId, dam.id);
        expect(puppy.sireId, sire.id);
        expect(puppy.species, 'dog');
        expect(puppy.birthDate, isNull);
        expect(puppy.createdAt, 10);
        expect(puppy.updatedAt, 10);
      }
    });

    test(
      'a puppy that cannot be written rolls the whole whelping back',
      () async {
        final dam = await daos.animals.create(
          _animal(name: 'Nala', sex: Sex.female, breeding: true),
          nowMs: 1,
        );
        // Reusing the dam's primary key makes the second animal insert fail.
        final collision = _animal(id: dam.id, name: 'clone');

        await expectLater(
          daos.litters.createWithPuppies(_litter(damId: dam.id), <Animal>[
            _puppy('A litter 1'),
            collision,
          ], nowMs: 5),
          throwsA(isA<DatabaseException>()),
        );

        expect(await daos.litters.all(), isEmpty);
        expect(await daos.animals.count(), 1);
        expect((await daos.animals.findById(dam.id))!.name, 'Nala');
      },
    );

    test('deleting the dam removes the litter but keeps the puppies', () async {
      final dam = await daos.animals.create(
        _animal(name: 'Nala', sex: Sex.female, breeding: true),
        nowMs: 1,
      );
      final created = await daos.litters.createWithPuppies(
        _litter(damId: dam.id),
        <Animal>[_puppy('A litter 1')],
        nowMs: 5,
      );
      expect(await daos.animals.findOffspring(created.id), hasLength(1));

      await daos.animals.delete(dam.id);

      expect(await daos.litters.all(), isEmpty);
      final survivors = await daos.animals.findAll();
      expect(survivors.map((a) => a.name), contains('A litter 1'));
      // `litter_id ON DELETE SET NULL`: the puppy stays, the link goes.
      expect(
        survivors.firstWhere((a) => a.name == 'A litter 1').litterId,
        isNull,
      );
    });

    test(
      'deleting the litter unlinks the puppies without deleting them',
      () async {
        final dam = await daos.animals.create(
          _animal(name: 'Nala', sex: Sex.female, breeding: true),
          nowMs: 1,
        );
        final created = await daos.litters.createWithPuppies(
          _litter(damId: dam.id),
          <Animal>[_puppy('A litter 1'), _puppy('A litter 2')],
          nowMs: 5,
        );

        await daos.litters.delete(created.id);

        expect(await daos.litters.all(), isEmpty);
        expect(await daos.animals.count(), 3);
        expect(await daos.animals.findOffspring(created.id), isEmpty);
      },
    );
  });
}
