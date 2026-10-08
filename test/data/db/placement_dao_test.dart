import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/placement.dart';

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

Future<String> seedBuyer(
  Daos daos, {
  String name = 'Youssef',
  String? phone = '060000000',
}) async {
  final created = await daos.buyers.create(
    Buyer(id: '', name: name, phone: phone, createdAt: 0, updatedAt: 0),
    nowMs: 1,
  );
  return created.id;
}

void main() {
  late Daos daos;
  late String animalId;
  late String buyerId;

  setUp(() async {
    final db = await openTestDatabase();
    daos = Daos(db);
    addTearDown(db.close);
    animalId = await seedAnimal(daos);
    buyerId = await seedBuyer(daos);
  });

  group('BuyerDao', () {
    test('round-trips the four things a contact is', () async {
      final created = await daos.buyers.create(
        Buyer(
          id: '',
          name: 'Amina',
          phone: '071111111',
          email: 'amina@example.test',
          countryCode: 'MA',
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 7,
      );

      final read = await daos.buyers.findById(created.id);
      expect(read, created);
      expect(read!.name, 'Amina');
      expect(read.phone, '071111111');
      expect(read.email, 'amina@example.test');
      expect(read.countryCode, 'MA');
      expect(read.createdAt, 7);
    });

    test(
      'a contact with no phone stores a null, not an empty string',
      () async {
        final created = await daos.buyers.create(
          Buyer(id: '', name: 'Bilal', createdAt: 0, updatedAt: 0),
          nowMs: 1,
        );

        final read = await daos.buyers.findById(created.id);
        expect(read!.phone, isNull);
        expect(read.email, isNull);
        expect(read.countryCode, isNull);
      },
    );

    test('alphabetical orders by name and ignores case', () async {
      await daos.buyers.create(
        Buyer(id: '', name: 'Ziad', createdAt: 0, updatedAt: 0),
        nowMs: 1,
      );
      await daos.buyers.create(
        Buyer(id: '', name: 'amina', createdAt: 0, updatedAt: 0),
        nowMs: 2,
      );

      final names = (await daos.buyers.alphabetical())
          .map((b) => b.name)
          .toList();
      // The seed buyer is 'Youssef', so the whole list is known here: a name
      // order is only worth having if it holds the contacts already filed.
      expect(names, <String>['amina', 'Youssef', 'Ziad']);
    });

    test('an update rewrites the contact and keeps when it was made', () async {
      final created = await daos.buyers.create(
        Buyer(
          id: '',
          name: 'Amina',
          phone: '071111111',
          createdAt: 0,
          updatedAt: 0,
        ),
        nowMs: 3,
      );
      await daos.buyers.update(created.copyWith(phone: '062222222'), nowMs: 9);

      final read = await daos.buyers.findById(created.id);
      expect(read!.phone, '062222222');
      expect(read.createdAt, 3);
      expect(read.updatedAt, 9);
    });

    test('a buyer that is not there reads as absent', () async {
      expect(await daos.buyers.findById('nobody'), isNull);
    });
  });

  group('PlacementDao', () {
    Placement handover({
      int? placed = 1000,
      double? price,
      String? currency = 'MAD',
      String? guarantee,
      String? notes,
    }) {
      return Placement(
        id: '',
        animalId: animalId,
        buyerId: buyerId,
        placedDate: placed,
        price: price,
        currency: currency,
        guaranteeTerms: guarantee,
        notes: notes,
        createdAt: 0,
        updatedAt: 0,
      );
    }

    test('round-trips the money, the terms and the day', () async {
      final created = await daos.placements.create(
        handover(
          placed: 5000,
          price: 2500.5,
          guarantee: 'Health guarantee for 15 days',
          notes: 'Deposit paid at the gate',
        ),
        nowMs: 7,
      );

      final read = await daos.placements.findById(created.id);
      expect(read, created);
      expect(read!.buyerId, buyerId);
      expect(read.placedDate, 5000);
      expect(read.price, 2500.5);
      expect(read.currency, 'MAD');
      expect(read.guaranteeTerms, 'Health guarantee for 15 days');
      expect(read.notes, 'Deposit paid at the gate');
      expect(read.createdAt, 7);
    });

    test('a placement with no price stores a null, not a zero', () async {
      final created = await daos.placements.create(handover(), nowMs: 1);

      final read = await daos.placements.findById(created.id);
      expect(read!.price, isNull);
    });

    test('an update can clear the price', () async {
      final created = await daos.placements.create(
        handover(price: 3000),
        nowMs: 1,
      );
      await daos.placements.update(
        created.copyWith(clearPrice: true),
        nowMs: 2,
      );

      expect((await daos.placements.findById(created.id))!.price, isNull);
    });

    test('an update can blank a handover that was mis-dated', () async {
      // The form writes the whole row rather than copying it, and `placed_date`
      // is nullable in the schema, so a blank day has to survive the round trip
      // as a blank day.
      final created = await daos.placements.create(
        handover(placed: 4000),
        nowMs: 1,
      );
      await daos.placements.update(
        Placement(
          id: created.id,
          animalId: animalId,
          buyerId: buyerId,
          placedDate: null,
          price: 250,
          currency: 'MAD',
          createdAt: created.createdAt,
          updatedAt: created.updatedAt,
        ),
        nowMs: 8,
      );

      final read = await daos.placements.findById(created.id);
      expect(read!.placedDate, isNull);
      expect(read.price, 250);
      expect(read.createdAt, 1);
      expect(read.updatedAt, 8);
    });

    test(
      'forAnimal returns only this animal, most recent handover first',
      () async {
        await daos.placements.create(handover(placed: 100), nowMs: 1);
        await daos.placements.create(handover(placed: 900), nowMs: 2);
        final other = await seedAnimal(daos, name: 'Other');
        await daos.placements.create(
          Placement(id: '', animalId: other, createdAt: 0, updatedAt: 0),
          nowMs: 3,
        );

        final mine = await daos.placements.forAnimal(animalId);
        expect(mine, hasLength(2));
        expect(mine.first.placedDate, 900);
        expect(await daos.placements.forAnimal('missing'), isEmpty);
      },
    );

    test('a handover with no day sorts after the ones that have one', () async {
      // SQLite reads NULL as the smallest value, so `placed_date DESC` puts an
      // undated row last rather than at the top of the ledger. This is the order
      // the transfer pack prints too, and the reason reading only `first` there
      // left an undated handover off the buyer's document: the pack now prints
      // every row, newest dated one first.
      await daos.placements.create(handover(placed: null), nowMs: 1);
      await daos.placements.create(handover(placed: 500), nowMs: 2);

      final mine = await daos.placements.forAnimal(animalId);
      expect(mine.map((p) => p.placedDate).toList(), <int?>[500, null]);
    });

    test('forBuyer answers with that buyer\'s most recent handover', () async {
      await daos.placements.create(handover(placed: 200), nowMs: 1);
      await daos.placements.create(handover(placed: 800), nowMs: 2);

      final newest = await daos.placements.forBuyer(buyerId);
      expect(newest!.placedDate, 800);
      expect(await daos.placements.forBuyer('nobody'), isNull);
    });

    test('deleting the buyer blanks the placement and keeps the row', () async {
      // `placements.buyer_id` is `ON DELETE SET NULL`: a contact removed from
      // the app must not erase the fact that an animal went to someone.
      final created = await daos.placements.create(handover(), nowMs: 1);
      await daos.buyers.delete(buyerId);

      final read = await daos.placements.findById(created.id);
      expect(read, isNotNull);
      expect(read!.buyerId, isNull);
      expect(read.placedDate, 1000);
    });

    test('deleting the animal takes its placements', () async {
      await daos.placements.create(handover(), nowMs: 1);
      await daos.animals.delete(animalId);

      expect(await daos.placements.forAnimal(animalId), isEmpty);
    });

    test('a placement for an animal that is not there is rejected', () async {
      await expectLater(
        daos.placements.create(
          Placement(id: '', animalId: 'nobody', createdAt: 0, updatedAt: 0),
        ),
        throwsA(anything),
      );
    });

    test('a placement naming a buyer that is not there is rejected', () async {
      // Same reason as the animal key: the buyer block of the document is only
      // as trustworthy as the row it points at.
      await expectLater(
        daos.placements.create(
          Placement(
            id: '',
            animalId: animalId,
            buyerId: 'ghost',
            createdAt: 0,
            updatedAt: 0,
          ),
        ),
        throwsA(anything),
      );
    });
  });
}
