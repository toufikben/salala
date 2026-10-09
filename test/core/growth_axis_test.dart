import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/growth_axis.dart';

/// The marks a growth curve is drawn against, before any page is drawn.
///
/// The axis of the first version was the set of ages the ledger happened to hold,
/// in days: a buyer's printed page read `988.0 1009.0 1012.0` under a curve, three
/// marks on top of each other, saying nothing about the animal's age and leaving no
/// way for CI to notice — the labels go through the embedded font's glyph ids, so
/// the only place they can be read is here (D29's rule, applied to a chart).
void main() {
  List<String> labelsOf(GrowthScale scale) => <String>[
    for (final GrowthTick tick in scale.ticks) tick.label,
  ];

  /// Every measurement has to sit between the two marks the plot scales by, or the
  /// point is painted outside the box the grid drew around it.
  void expectSpans(GrowthScale scale, List<double> measured) {
    expect(
      scale.values.first,
      lessThanOrEqualTo(measured.reduce((double a, double b) => a < b ? a : b)),
      reason: 'the youngest or lightest measurement fell off the left edge',
    );
    expect(
      scale.values.last,
      greaterThanOrEqualTo(
        measured.reduce((double a, double b) => a > b ? a : b),
      ),
      reason: 'the oldest or heaviest measurement fell off the right edge',
    );
  }

  void expectAscending(GrowthScale scale) {
    for (var i = 1; i < scale.values.length; i++) {
      expect(
        scale.values[i],
        greaterThan(scale.values[i - 1]),
        reason:
            'mark $i is not after mark ${i - 1}, and the axis asserts order',
      );
    }
    expect(
      scale.labels.length,
      scale.ticks.length,
      reason: 'two marks landed on the same value, so one label was lost',
    );
  }

  group('monthScale', () {
    test('the ages a grown animal was weighed at are said as months', () {
      // The set the phone actually produced: three weigh-ins close together on a
      // near-three-year-old dam, which the old axis printed as raw day counts.
      final scale = monthScale(agesInDays: <double>[988, 1009, 1012]);

      expect(labelsOf(scale), <String>['32', '33', '34']);
      expect(
        labelsOf(scale).where((String label) => label.contains('.')),
        isEmpty,
        reason: 'a fractional month mark reads as a mistake on paper',
      );
      expectAscending(scale);
      expectSpans(scale, <double>[988, 1009, 1012]);
    });

    test('a puppy weighed from birth is marked at every month it lived', () {
      final scale = monthScale(agesInDays: <double>[0, 30, 61, 92]);

      expect(labelsOf(scale), <String>['0', '1', '2', '3', '4']);
      expectAscending(scale);
      expectSpans(scale, <double>[0, 30, 61, 92]);
    });

    test('a long record is thinned, and still ends at the oldest weigh-in', () {
      final scale = monthScale(agesInDays: <double>[5, 400, 700, 900]);

      expect(labelsOf(scale), <String>['0', '6', '12', '18', '24', '30']);
      expect(scale.ticks.length, lessThanOrEqualTo(6));
      expectAscending(scale);
      expectSpans(scale, <double>[5, 400, 700, 900]);
    });

    test('two weigh-ins inside one month still give the plot a span', () {
      // One mark would make the axis's whole width zero — the divisor every point
      // is scaled by — and the curve would be painted at the edge of the box.
      final scale = monthScale(agesInDays: <double>[40, 45]);

      expect(labelsOf(scale), <String>['1', '2']);
      expectAscending(scale);
      expectSpans(scale, <double>[40, 45]);
    });

    test('every mark the axis is built from has a word for itself', () {
      // `pw.FixedAxis` asks for the label of exactly these values, so a value with
      // no word is a blank printed under the curve.
      final scale = monthScale(agesInDays: <double>[5, 400, 700, 900]);

      for (final double value in scale.values) {
        expect(scale.format(value), isNotEmpty);
      }
      expect(scale.format(scale.values.first), '0');
    });
  });

  group('kiloScale', () {
    test('a newborn in grams and a dam in kilograms share one axis', () {
      final scale = kiloScale(weightsInKg: <double>[0.43, 3.1, 12.5, 35.2]);

      expect(labelsOf(scale), <String>['0', '10', '20', '30', '40']);
      expectAscending(scale);
      expectSpans(scale, <double>[0.43, 3.1, 12.5, 35.2]);
    });

    test('a whole kilogram is said as 3, not as 3.0', () {
      final scale = kiloScale(weightsInKg: <double>[2.5, 3.0]);

      expect(labelsOf(scale), <String>['2.5', '2.6', '2.7', '2.8', '2.9', '3']);
      expectAscending(scale);
      expectSpans(scale, <double>[2.5, 3.0]);
    });

    test('a few grams apart are still two readable marks', () {
      // A scale that resolves grams makes neighbouring weights a real pair, and the
      // step must go on to meet them rather than print one point.
      final scale = kiloScale(weightsInKg: <double>[3.01, 3.04]);

      expect(labelsOf(scale), <String>['3.01', '3.02', '3.03', '3.04']);
      expectAscending(scale);
      expectSpans(scale, <double>[3.01, 3.04]);
    });

    test('no weight axis is asked to print more than six marks', () {
      final scale = kiloScale(weightsInKg: <double>[0.43, 5.5, 19.75, 35.2]);

      expect(scale.ticks.length, lessThanOrEqualTo(6));
      expectAscending(scale);
      expectSpans(scale, <double>[0.43, 5.5, 19.75, 35.2]);
      for (final double value in scale.values) {
        expect(scale.format(value), isNotEmpty);
      }
    });
  });

  group('meanDaysPerMonth', () {
    test('is the month a calendar agrees roughly with', () {
      // The axis is in months and the ledger is in days; if this drifts from a real
      // month, the marks stop answering "how old was she".
      expect(meanDaysPerMonth, closeTo(30.44, 0.01));
      expect(12 * meanDaysPerMonth, closeTo(365.2425, 0.01));
    });
  });
}
