import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
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

  group('HealthTestDao', () {
    HealthTest scan({
      String type = 'OFA hips',
      String result = 'Good',
      int at = 1000,
      int? until,
    }) {
      return HealthTest(
        id: '',
        animalId: animalId,
        testType: type,
        result: result,
        testDate: at,
        validUntil: until,
        createdAt: 0,
        updatedAt: 0,
      );
    }

    test('round-trips the certificate paperwork', () async {
      final created = await daos.healthTests.create(
        scan(at: 500, until: 9000).copyWith(
          testingBody: 'OFA',
          certificateNo: '12345',
          verifiedBy: 'Dr Atlas',
        ),
        nowMs: 1,
      );

      final read = await daos.healthTests.findById(created.id);
      expect(read!.certificateNo, '12345');
      expect(read.testingBody, 'OFA');
      expect(read.validUntil, 9000);
    });

    test('newest screening first, and only this animal\'s', () async {
      await daos.healthTests.create(scan(type: 'BAER', at: 10), nowMs: 1);
      await daos.healthTests.create(scan(at: 30), nowMs: 2);

      final rows = await daos.healthTests.forAnimal(animalId);
      expect(rows.map((r) => r.testDate).toList(), <int>[30, 10]);
      expect(await daos.healthTests.forAnimal('missing'), isEmpty);
    });

    test('a certificate with no expiry never lapses', () {
      expect(scan(until: 1000).isExpired(1001), isTrue);
      expect(scan().isExpired(1000), isFalse);
    });

    test('an update can clear the expiry', () async {
      final created = await daos.healthTests.create(
        scan(until: 9000),
        nowMs: 1,
      );
      await daos.healthTests.update(
        created.copyWith(clearValidUntil: true),
        nowMs: 2,
      );

      expect((await daos.healthTests.findById(created.id))!.validUntil, isNull);
    });
  });

  group('VetVisitDao', () {
    VetVisit visit({int at = 1000, double? cost}) => VetVisit(
      id: '',
      animalId: animalId,
      visitDate: at,
      cost: cost,
      createdAt: 0,
      updatedAt: 0,
    );

    test('a decimal fee survives the round trip', () async {
      final created = await daos.vetVisits.create(
        visit(cost: 250.5).copyWith(currency: 'MAD', clinicName: 'Atlas'),
        nowMs: 1,
      );

      expect(await daos.vetVisits.findById(created.id), created);
      final row = await daos.vetVisits.findById(created.id);
      expect(row!.cost, 250.5);
      expect(row.currency, 'MAD');
      expect(row.clinicName, 'Atlas');
    });

    test('a visit with no fee stores a null, not a zero', () async {
      final created = await daos.vetVisits.create(visit(), nowMs: 1);
      final row = await daos.vetVisits.findById(created.id);
      expect(row!.cost, isNull);
    });

    test('newest visit first', () async {
      await daos.vetVisits.create(visit(at: 10), nowMs: 1);
      await daos.vetVisits.create(visit(at: 40), nowMs: 2);

      final rows = await daos.vetVisits.forAnimal(animalId);
      expect(rows.map((r) => r.visitDate).toList(), <int>[40, 10]);
    });
  });
}
