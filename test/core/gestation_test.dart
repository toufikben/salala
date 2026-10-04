import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/gestation.dart';

void main() {
  group('expectedWhelpingDate', () {
    test('counts 63 days for a dog', () {
      final mating = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final expected = expectedWhelpingDate(
        species: 'dog',
        matingDate: mating,
      )!;
      final day = DateTime.fromMillisecondsSinceEpoch(expected);
      expect([day.year, day.month, day.day], [2026, 3, 5]);
    });

    test('counts 65 days for a cat', () {
      final mating = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final expected = expectedWhelpingDate(
        species: 'cat',
        matingDate: mating,
      )!;
      final day = DateTime.fromMillisecondsSinceEpoch(expected);
      expect([day.year, day.month, day.day], [2026, 3, 7]);
    });

    test('species matching ignores case and spacing', () {
      final mating = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      expect(
        expectedWhelpingDate(species: ' DOG ', matingDate: mating),
        expectedWhelpingDate(species: 'dog', matingDate: mating),
      );
    });

    test('an unlisted species gets no estimate instead of dog arithmetic', () {
      final mating = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      expect(
        expectedWhelpingDate(species: 'rabbit', matingDate: mating),
        isNull,
      );
    });

    test('a missing mating date or species yields no estimate', () {
      final mating = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      expect(expectedWhelpingDate(species: 'dog', matingDate: null), isNull);
      expect(expectedWhelpingDate(species: null, matingDate: mating), isNull);
    });
  });
}
