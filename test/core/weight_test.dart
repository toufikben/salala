import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/weight.dart';

void main() {
  group('formatWeight', () {
    test('a puppy is described in grams', () {
      expect(formatWeight(430), '430 g');
      expect(formatWeight(999), '999 g');
    });

    test('from a kilogram up the unit switches', () {
      expect(formatWeight(1000), '1.00 kg');
      expect(formatWeight(4200), '4.20 kg');
      expect(formatWeight(31250), '31.25 kg');
    });
  });

  group('parseWeightToGrams', () {
    test('reads a kilogram value off the scale', () {
      expect(parseWeightToGrams('4.2'), 4200);
      expect(parseWeightToGrams('0.43'), 430);
      expect(parseWeightToGrams('31'), 31000);
    });

    test('accepts the comma a European keyboard prints', () {
      expect(parseWeightToGrams('4,200'), 4200);
    });

    test('round-trips with the formatter', () {
      expect(formatWeight(parseWeightToGrams('4.2')!), '4.20 kg');
    });

    test('refuses anything that is not a positive weight', () {
      expect(parseWeightToGrams(''), isNull);
      expect(parseWeightToGrams('   '), isNull);
      expect(parseWeightToGrams('abc'), isNull);
      expect(parseWeightToGrams('0'), isNull);
      expect(parseWeightToGrams('-2.5'), isNull);
      // Below a tenth of a gram is a typing mistake, not a measurement.
      expect(parseWeightToGrams('0.00004'), isNull);
    });
  });
}
