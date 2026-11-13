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
  int? whelpingDate = 200,
}) {
  return Litter(
    id: '',
    name: name,
    damId: damId,
    sireId: sireId,
    matingDate: 100,
    whelpingDate: whelpingDate,
    weaningDate: null,
    notes: '',
    createdAt: 0,
    updatedAt: 0,
  );
}

Animal _puppy(String name, {int? birthDate}) => Animal(
  id: '',
  name: name,
  species: 'dog',
  sex: Sex.unknown,
  status: AnimalStatus.active,
  breed: 'Border collie',
  birthDate: birthDate,
  createdAt: 0,
  updatedAt: 0,
);

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

  group('LitterDao.addPuppies', () {
    test('numbers the new puppies after the ones already registered', () async {
      final dam = await daos.animals.create(
        _animal(name: 'Nala', sex: Sex.female, breeding: true),
        nowMs: 1,
      );
      final sire = await daos.animals.create(
        _animal(name: 'Atlas', sex: Sex.male, breeding: true),
        nowMs: 2,
      );
      final litter = await daos.litters.createWithPuppies(
        _litter(damId: dam.id, sireId: sire.id),
        <Animal>[_puppy('A litter 1'), _puppy('A litter 2')],
        nowMs: 10,
      );

      final added = await daos.litters.addPuppies(litter, 2, nowMs: 30);

      // Numbering continues: a second visit must read as one whelping, not as
      // two litters whose puppies share the first two names.
      expect(added.map((p) => p.name), <String>['A litter 3', 'A litter 4']);
      for (final puppy in added) {
        expect(puppy.litterId, litter.id);
        expect(puppy.damId, dam.id);
        expect(puppy.sireId, sire.id);
        expect(puppy.species, 'dog');
        expect(puppy.breed, 'Border collie');
        // The whelping date is the day they were born, not today.
        expect(puppy.birthDate, 200);
        expect(puppy.createdAt, 30);
      }

      final all = await daos.animals.findOffspring(litter.id);
      expect(all.map((p) => p.name), <String>[
        'A litter 1',
        'A litter 2',
        'A litter 3',
        'A litter 4',
      ]);
    });

    test('a count of nothing is not a write', () async {
      final dam = await daos.animals.create(
        _animal(name: 'Nala', sex: Sex.female, breeding: true),
        nowMs: 1,
      );
      final litter = await daos.litters.createWithPuppies(
        _litter(damId: dam.id),
        <Animal>[_puppy('A litter 1')],
        nowMs: 10,
      );

      expect(await daos.litters.addPuppies(litter, 0), isEmpty);
      expect(await daos.animals.findOffspring(litter.id), hasLength(1));
    });
  });

  group('LitterDao.retargetPuppies', () {
    test('a corrected whelping date moves the puppies that still carry it', () async {
      final dam = await daos.animals.create(
        _animal(name: 'Nala', sex: Sex.female, breeding: true),
        nowMs: 1,
      );
      final litter = await daos.litters.createWithPuppies(
        _litter(damId: dam.id),
        <Animal>[
          _puppy('A litter 1', birthDate: 200),
          _puppy('A litter 2', birthDate: 200),
        ],
        nowMs: 10,
      );
      // The breeder corrected one birthday by hand before noticing the whelping
      // date was wrong; that correction is hers and must survive.
      final puppies = await daos.animals.findOffspring(litter.id);
      final byName = <String, Animal>{
        for (final puppy in puppies) puppy.name: puppy,
      };
      await daos.animals.update(
        byName['A litter 1']!.copyWith(birthDate: 250),
        nowMs: 20,
      );

      final updated = litter.copyWith(whelpingDate: 300);
      await daos.litters.update(updated);
      await daos.litters.retargetPuppies(
        previous: litter,
        updated: updated,
        nowMs: 40,
      );

      final after = await daos.animals.findOffspring(litter.id);
      expect(
        after.firstWhere((p) => p.name == 'A litter 1').birthDate,
        250,
        reason: 'a birthday the breeder set herself is not a copy to overwrite',
      );
      expect(
        after.firstWhere((p) => p.name == 'A litter 2').birthDate,
        300,
        reason:
            'the copy of the old whelping date has to follow the correction',
      );
    });

    test('a corrected dam and sire are carried into the puppies', () async {
      final dam = await daos.animals.create(
        _animal(name: 'Nala', sex: Sex.female, breeding: true),
        nowMs: 1,
      );
      final otherDam = await daos.animals.create(
        _animal(name: 'Suki', sex: Sex.female, breeding: true),
        nowMs: 2,
      );
      final litter = await daos.litters.createWithPuppies(
        _litter(damId: dam.id),
        <Animal>[_puppy('A litter 1')],
        nowMs: 10,
      );

      final updated = litter.copyWith(damId: otherDam.id);
      await daos.litters.update(updated);
      await daos.litters.retargetPuppies(
        previous: litter,
        updated: updated,
        nowMs: 40,
      );

      final puppies = await daos.animals.findOffspring(litter.id);
      expect(puppies.single.damId, otherDam.id);
      // A puppy's pack prints its dam beside the whelping it came from; two
      // names for one mother would be the ledger lying to a buyer.
      expect(puppies.single.sireId, isNull);
    });
  });
}
