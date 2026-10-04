import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';

import '../../helpers/test_db.dart';

Future<String> seedAnimal(Daos daos, {String name = 'Atlas'}) async {
  final created = await daos.animals.create(
    Animal(
      id: '',
      name: name,
      species: 'dog',
      sex: Sex.male,
      status: AnimalStatus.active,
      createdAt: 0,
      updatedAt: 0,
    ),
    nowMs: 1,
  );
  return created.id;
}

void main() {
  late Daos daos;
  late String animalId;

  setUp(() async {
    final db = await openTestDatabase();
    daos = Daos(db);
    addTearDown(db.close);
    animalId = await seedAnimal(daos);
  });

  group('VaccinationDao', () {
    Vaccination shot({
      String name = 'Rabies',
      int administered = 1000,
      int? due,
    }) {
      return Vaccination(
        id: '',
        animalId: animalId,
        vaccineName: name,
        dateAdministered: administered,
        nextDueDate: due,
        createdAt: 0,
        updatedAt: 0,
      );
    }

    test('round-trips through the database', () async {
      final created = await daos.vaccinations.create(
        shot(name: 'DHPP', due: 9000),
        nowMs: 7,
      );
      final readBack = await daos.vaccinations.findById(created.id);
      expect(readBack, created);
      expect(readBack!.nextDueDate, 9000);
    });

    test('forAnimal returns only this animal, most recent first', () async {
      await daos.vaccinations.create(shot(administered: 100), nowMs: 1);
      await daos.vaccinations.create(shot(administered: 900), nowMs: 2);
      final other = await daos.animals.create(
        Animal(
          id: '',
          name: 'Other',
          species: 'cat',
          sex: Sex.female,
          status: AnimalStatus.active,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 1,
      );
      await daos.vaccinations.create(
        Vaccination(
          id: '',
          animalId: other.id,
          vaccineName: 'FVRCP',
          dateAdministered: 5000,
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 1,
      );

      final mine = await daos.vaccinations.forAnimal(animalId);
      expect(mine, hasLength(2));
      expect(mine.first.dateAdministered, 900);
    });

    test('dueBefore skips doses without a due date', () async {
      await daos.vaccinations.create(shot(due: 5000), nowMs: 1);
      await daos.vaccinations.create(shot(name: 'No due date'), nowMs: 2);
      await daos.vaccinations.create(shot(name: 'Later', due: 50000), nowMs: 3);

      final due = await daos.vaccinations.dueBefore(10000);
      expect(due.map((v) => v.vaccineName).toList(), <String>['Rabies']);
    });

    test('isOverdue reads the clock, not the database', () {
      final v = shot(due: 1000);
      expect(v.isOverdue(1001), isTrue);
      expect(v.isOverdue(999), isFalse);
      expect(shot().isOverdue(1000), isFalse);
    });
  });

  group('WeightDao', () {
    WeightEntry gram(int grams, int at) => WeightEntry(
      id: '',
      animalId: animalId,
      weightGrams: grams,
      measuredAt: at,
    );

    test('appends oldest-first for charting', () async {
      await daos.weights.create(gram(400, 30), nowMs: 1);
      await daos.weights.create(gram(300, 10), nowMs: 2);
      await daos.weights.create(gram(350, 20), nowMs: 3);

      final series = await daos.weights.forAnimal(animalId);
      expect(series.map((w) => w.measuredAt).toList(), <int>[10, 20, 30]);
      expect(series.last.weightKg, closeTo(0.4, 0.0001));
    });

    test('latestFor answers the litter dashboard', () async {
      await daos.weights.create(gram(200, 10), nowMs: 1);
      await daos.weights.create(gram(400, 40), nowMs: 2);
      expect((await daos.weights.latestFor(animalId))!.weightGrams, 400);
      expect(await daos.weights.latestFor('missing'), isNull);
    });

    test('an append-only row carries no timestamp columns', () async {
      final created = await daos.weights.create(gram(500, 1000), nowMs: 42);
      expect(created.toMap().containsKey('created_at'), isFalse);
      expect(await daos.weights.findById(created.id), created);
    });
  });
}
