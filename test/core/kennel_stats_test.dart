import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/kennel_stats.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/placement.dart';

/// A calendar day, as the app stores one.
int day(int year, int month, int dayOfMonth) =>
    DateTime(year, month, dayOfMonth).millisecondsSinceEpoch;

Animal animal(
  String id, {
  Sex sex = Sex.female,
  AnimalStatus status = AnimalStatus.active,
  bool breeding = false,
  int? birthDate,
  String? litterId,
}) => Animal(
  id: id,
  name: 'Animal $id',
  species: 'dog',
  sex: sex,
  status: status,
  createdAt: 0,
  updatedAt: 0,
  isBreedingStock: breeding,
  birthDate: birthDate,
  litterId: litterId,
);

Litter litter(String id, int? whelpingDate) => Litter(
  id: id,
  name: 'Litter $id',
  damId: 'dam',
  createdAt: 0,
  updatedAt: 0,
  whelpingDate: whelpingDate,
);

Placement placement(String id, {double? price, String? currency}) => Placement(
  id: id,
  animalId: 'a$id',
  createdAt: 0,
  updatedAt: 0,
  price: price,
  currency: currency,
);

void main() {
  group('kennelStats', () {
    test('an empty ledger is empty, not a division by nothing', () {
      final stats = kennelStats(
        animals: const <Animal>[],
        litters: const <Litter>[],
        placements: const <Placement>[],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.isEmpty, isTrue);
      expect(stats.atHome, 0);
      expect(stats.revenue, isEmpty);
      expect(stats.thisYear, 2026);
    });

    test('sold, dead and retired animals are counted apart', () {
      final stats = kennelStats(
        animals: <Animal>[
          animal('1'),
          animal('2', status: AnimalStatus.retired),
          animal('3', status: AnimalStatus.sold),
          animal('4', status: AnimalStatus.deceased),
        ],
        litters: const <Litter>[],
        placements: const <Placement>[],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.everRecorded, 4);
      // Retired still lives here and is still owed her reminders.
      expect(stats.atHome, 2);
    });

    test('the sexes and breeding stock count only who is here', () {
      final stats = kennelStats(
        animals: <Animal>[
          animal('1', sex: Sex.male, breeding: true),
          animal('2', sex: Sex.female, breeding: true),
          animal('3', sex: Sex.female),
          animal('4', sex: Sex.male, status: AnimalStatus.sold),
        ],
        litters: const <Litter>[],
        placements: const <Placement>[],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.males, 1);
      expect(stats.females, 2);
      expect(stats.breedingStock, 2);
    });

    test('an undated whelping is not a whelping in a year', () {
      final stats = kennelStats(
        animals: const <Animal>[],
        litters: <Litter>[
          litter('a', day(2026, 3, 1)),
          litter('b', null),
          litter('c', day(2025, 3, 1)),
        ],
        placements: const <Placement>[],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.whelpings, 2);
      expect(stats.puppiesThisYear, 0);
    });

    test('puppies this year counts births, not handovers', () {
      final stats = kennelStats(
        animals: <Animal>[
          animal('1', birthDate: day(2026, 1, 4), litterId: 'L1'),
          animal('2', birthDate: day(2026, 1, 4), litterId: 'L1'),
          animal('3', birthDate: day(2026, 1, 4), litterId: 'L1',
              status: AnimalStatus.sold),
          animal('4', birthDate: day(2025, 1, 4), litterId: 'L0'),
          animal('5'),
        ],
        litters: <Litter>[litter('L1', day(2026, 1, 4))],
        placements: const <Placement>[],
        nowMs: day(2026, 6, 1),
      );

      // Three born this year, one of them already placed.
      expect(stats.puppiesThisYear, 3);
      // Two litters' worth of puppies in the whole record.
      expect(stats.puppiesRegistered, 4);
    });

    test('revenue keeps one total per currency and never adds them', () {
      final stats = kennelStats(
        animals: const <Animal>[],
        litters: const <Litter>[],
        placements: <Placement>[
          placement('1', price: 2000, currency: 'mad'),
          placement('2', price: 500, currency: 'MAD'),
          placement('3', price: 1800, currency: 'EUR'),
          placement('4'),
        ],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.revenue.length, 2);
      // Biggest total first, and the case of the typed currency is folded.
      expect(stats.revenue.first.currency, 'MAD');
      expect(stats.revenue.first.total, 2500);
      expect(stats.revenue.first.count, 2);
      expect(stats.revenue.last.currency, 'EUR');
      expect(stats.revenue.last.total, 1800);
      // A priced handover with no currency typed is its own row, not a guess.
      expect(stats.placements, 3);
    });

    test('a price with no currency is kept as an unnamed total', () {
      final stats = kennelStats(
        animals: const <Animal>[],
        litters: const <Litter>[],
        placements: <Placement>[placement('1', price: 2500)],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.revenue.single.currency, '');
      expect(stats.revenue.single.total, 2500);
    });

    test('a handover with no price is a placement but not revenue', () {
      final stats = kennelStats(
        animals: const <Animal>[],
        litters: const <Litter>[],
        placements: <Placement>[placement('1')],
        nowMs: day(2026, 6, 1),
      );

      expect(stats.revenue, isEmpty);
    });
  });

  group('birthdaysSoon', () {
    test('a birthday today is zero days away', () {
      final found = birthdaysSoon(
        <Animal>[animal('1', birthDate: day(2023, 6, 1))],
        nowMs: day(2026, 6, 1),
      );

      expect(found.single.days, 0);
      expect(found.single.turning, 3);
    });

    test('a birthday inside the window is listed, one outside is not', () {
      final found = birthdaysSoon(
        <Animal>[
          animal('near', birthDate: day(2020, 6, 9)),
          animal('far', birthDate: day(2020, 8, 1)),
        ],
        nowMs: day(2026, 6, 1),
      );

      expect(found.map((b) => b.animalId), <String>['near']);
      expect(found.single.days, 8);
      expect(found.single.turning, 6);
    });

    test('a birthday just gone by comes round again next year', () {
      final found = birthdaysSoon(
        <Animal>[animal('1', birthDate: day(2019, 5, 30))],
        nowMs: day(2026, 6, 1),
        withinDays: 400,
      );

      // 30 May 2027 — 363 days off, not "two days ago". June is 30 days long, so
      // a year from 1 June lands on 1 June and two days come off that.
      expect(found.single.days, 363);
      expect(found.single.turning, 8);
    });

    test('an animal who died is not celebrated', () {
      final found = birthdaysSoon(
        <Animal>[
          animal('gone', birthDate: day(2018, 6, 2),
              status: AnimalStatus.deceased),
          animal('sold', birthDate: day(2018, 6, 2),
              status: AnimalStatus.sold),
        ],
        nowMs: day(2026, 6, 1),
      );

      expect(found, isEmpty);
    });

    test('no birth date is not a birthday', () {
      expect(birthdaysSoon(<Animal>[animal('1')], nowMs: day(2026, 6, 1)), isEmpty);
    });

    test('a leap-day birthday lands on 1 March in a common year', () {
      final found = birthdaysSoon(
        <Animal>[animal('1', birthDate: day(2020, 2, 29))],
        nowMs: day(2026, 2, 20),
      );

      expect(found.single.days, 9);
      expect(found.single.turning, 6);
    });

    test('two on the same day are ordered by name, not by the hash', () {
      final found = birthdaysSoon(
        <Animal>[
          Animal(
            id: 'b',
            name: 'Zina',
            species: 'dog',
            sex: Sex.female,
            status: AnimalStatus.active,
            createdAt: 0,
            updatedAt: 0,
            birthDate: day(2021, 6, 3),
          ),
          Animal(
            id: 'a',
            name: 'Amina',
            species: 'dog',
            sex: Sex.female,
            status: AnimalStatus.active,
            createdAt: 0,
            updatedAt: 0,
            birthDate: day(2021, 6, 3),
          ),
        ],
        nowMs: day(2026, 6, 1),
      );

      expect(found.map((b) => b.name), <String>['Amina', 'Zina']);
    });
  });
}
