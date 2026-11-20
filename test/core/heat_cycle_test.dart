import 'package:flutter_test/flutter_test.dart';
import 'package:companion/core/utils/heat_cycle.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/data/models/litter.dart';

/// A day, as the app stores days: local midnight in unix milliseconds.
int day(int year, int month, int dayOfMonth) =>
    DateTime(year, month, dayOfMonth).millisecondsSinceEpoch;

Animal dam({String id = 'dam-1', Sex sex = Sex.female}) => Animal(
  id: id,
  name: 'Nala',
  species: 'dog',
  sex: sex,
  status: AnimalStatus.active,
  createdAt: 0,
  updatedAt: 0,
);

Litter mating(String id, int? matingDate, {String damId = 'dam-1'}) => Litter(
  id: id,
  name: 'L $id',
  damId: damId,
  createdAt: 0,
  updatedAt: 0,
  matingDate: matingDate,
);

void main() {
  group('heatsOf', () {
    test('keeps only this dam matings, newest first', () {
      final litters = <Litter>[
        mating('a', day(2026, 1, 1)),
        mating('b', day(2026, 5, 1)),
        mating('c', day(2026, 3, 1)),
        mating('d', day(2025, 11, 1), damId: 'dam-2'),
      ];

      expect(
        heatsOf(litters, 'dam-1').map((litter) => litter.id),
        <String>['b', 'c', 'a'],
      );
    });

    test('a mating with no date is not a heat', () {
      final litters = <Litter>[mating('a', null), mating('b', day(2026, 1, 1))];

      expect(heatsOf(litters, 'dam-1').map((litter) => litter.id), ['b']);
    });
  });

  group('forecastHeat', () {
    test('a male gets no forecast at all', () {
      final litters = <Litter>[
        mating('a', day(2026, 1, 1)),
        mating('b', day(2026, 3, 1)),
      ];

      expect(forecastHeat(litters, dam(sex: Sex.male)), isNull);
    });

    test('one heat on file is not a cycle', () {
      final litters = <Litter>[mating('a', day(2026, 1, 1))];

      expect(forecastHeat(litters, dam()), isNull);
    });

    test('no matings at all is not a cycle', () {
      expect(forecastHeat(const <Litter>[], dam()), isNull);
    });

    test('two matings on one day are one heat, not a cycle of zero', () {
      final litters = <Litter>[
        mating('a', day(2026, 1, 1)),
        mating('b', day(2026, 1, 1)),
      ];

      expect(forecastHeat(litters, dam()), isNull);
    });

    test('two heats give the observed gap and a wide window', () {
      final litters = <Litter>[
        mating('a', day(2026, 1, 1)),
        mating('b', day(2026, 3, 1)),
      ];

      final forecast = forecastHeat(litters, dam())!;

      expect(forecast.observedCycles, 1);
      expect(forecast.averageGapDays, 59);
      expect(forecast.confidence, HeatConfidence.thin);
      // Estimated from the newest mating, not the oldest.
      expect(forecast.estimated, day(2026, 4, 29));
      // One interval either side, because one gap can be a coincidence.
      expect(forecast.earliest, day(2026, 3, 1));
      expect(forecast.latest, day(2026, 6, 27));
    });

    test('three heats average their gaps and narrow the window', () {
      final litters = <Litter>[
        mating('a', day(2026, 1, 1)),
        mating('b', day(2026, 3, 1)),
        mating('c', day(2026, 5, 1)),
      ];

      final forecast = forecastHeat(litters, dam())!;

      // Gaps of 59 and 61 days average to 60.
      expect(forecast.observedCycles, 2);
      expect(forecast.averageGapDays, 60);
      expect(forecast.confidence, HeatConfidence.steady);
      expect(forecast.estimated, day(2026, 6, 30));
      expect(forecast.earliest, day(2026, 6, 9));
      expect(forecast.latest, day(2026, 7, 21));
    });

    test('the estimate always sits inside its own window', () {
      final litters = <Litter>[
        mating('a', day(2025, 2, 14)),
        mating('b', day(2025, 8, 3)),
        mating('c', day(2026, 1, 20)),
      ];

      final forecast = forecastHeat(litters, dam())!;

      expect(forecast.earliest, lessThan(forecast.estimated));
      expect(forecast.latest, greaterThan(forecast.estimated));
    });

    test('another dam in the same list changes nothing', () {
      final litters = <Litter>[
        mating('a', day(2026, 1, 1)),
        mating('b', day(2026, 3, 1)),
        mating('c', day(2025, 1, 1), damId: 'dam-2'),
        mating('d', day(2025, 9, 1), damId: 'dam-2'),
      ];

      final forecast = forecastHeat(litters, dam())!;

      expect(forecast.observedCycles, 1);
      expect(forecast.averageGapDays, 59);
    });

    test('a mating across a daylight-saving change still lands on a day', () {
      // 28 March 2026 is the European switch; adding calendar days rather than
      // 24-hour blocks keeps the estimate on the day a breeder counts.
      final litters = <Litter>[
        mating('a', day(2025, 9, 20)),
        mating('b', day(2026, 3, 21)),
      ];

      final forecast = forecastHeat(litters, dam())!;
      final estimate = DateTime.fromMillisecondsSinceEpoch(forecast.estimated);

      // 182 days later, which is 21 September 2026 by the calendar.
      expect([estimate.year, estimate.month, estimate.day], [2026, 9, 19]);
    });
  });
}
