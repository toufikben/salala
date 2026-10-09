import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/growth_axis.dart';

/// The seed of the sweep below, fixed so CI and a laptop see the same inputs.
const int _sweepSeed = 20261009;

/// How many records each scale is asked to lay out.
const int _sweepRuns = 1500;

/// An age no dog lives to, so the sweep covers a birth date typed four digits wrong.
const double _oldestAgeDays = 20000;

/// A weight past anything on the page: the field has no maximum, so 430 grams typed
/// into the kilogram box arrives as 430, and a finger on `0` arrives as thousands.
const double _heaviestTypedKilos = 5000;

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

    test('the axis stops at the month the record reaches', () {
      // The marks go by threes and the oldest weigh-in is fourteen months old, so
      // the range closes on a mark two months past the last whole step. Without it
      // that weigh-in is painted past the edge of the box.
      final scale = monthScale(agesInDays: <double>[30, 400]);

      expect(labelsOf(scale), <String>['0', '3', '6', '9', '12', '14']);
      expectAscending(scale);
      expectSpans(scale, <double>[30, 400]);
    });

    test('a dog weighed for four years is marked once a year', () {
      final scale = monthScale(agesInDays: <double>[5, 1460]);

      expect(labelsOf(scale), <String>['0', '12', '24', '36', '48']);
      expect(scale.ticks.length, lessThanOrEqualTo(6));
      expectAscending(scale);
      expectSpans(scale, <double>[5, 1460]);
    });

    test('the last year before a dam is retired is still marked monthly', () {
      final scale = monthScale(agesInDays: <double>[1095, 1200]);

      expect(labelsOf(scale), <String>['35', '36', '37', '38', '39', '40']);
      expectAscending(scale);
      expectSpans(scale, <double>[1095, 1200]);
    });

    test('an age no animal lives to is still thinned, not crowded', () {
      // The month ladder stops at a decade because that is as long as a dog is
      // tracked for; a birth date typed four digits wrong goes past it. The marks
      // then thin by whole steps instead of running off the end of the ladder, so
      // the page still gets a readable number of them.
      final scale = monthScale(agesInDays: <double>[0, 100000]);

      expect(labelsOf(scale), <String>[
        '0',
        '720',
        '1440',
        '2160',
        '2880',
        '3286',
      ]);
      expect(scale.ticks.length, lessThanOrEqualTo(6));
      expectAscending(scale);
      expectSpans(scale, <double>[0, 100000]);
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

    test('a range that starts mid-step is marked from the step below it', () {
      // Three grown dogs, none of them on a multiple of the step the axis ends up
      // using: the lightest weigh-in has to sit inside the marks, not on the edge
      // the plot cannot reach.
      final scale = kiloScale(weightsInKg: <double>[16, 22, 29]);

      expect(labelsOf(scale), <String>['15', '20', '25', '30']);
      expectAscending(scale);
      expectSpans(scale, <double>[16, 22, 29]);
    });

    test('a heavy dog range is marked in whole tens', () {
      final scale = kiloScale(weightsInKg: <double>[60, 75, 90, 110]);

      expect(labelsOf(scale), <String>['60', '70', '80', '90', '100', '110']);
      expect(scale.ticks.length, lessThanOrEqualTo(6));
      expectAscending(scale);
      expectSpans(scale, <double>[60, 75, 90, 110]);
    });

    test('two weigh-ins the scale barely moved between are still readable', () {
      final scale = kiloScale(weightsInKg: <double>[0.43, 0.43, 0.45]);

      expect(labelsOf(scale), <String>['0.43', '0.44', '0.45']);
      expectAscending(scale);
      expectSpans(scale, <double>[0.43, 0.43, 0.45]);
    });

    test('two identical weigh-ins still give the plot a width', () {
      // A dam weighed on the day she arrived and the day she left. One mark would
      // make the axis's whole span zero — the divisor every point is scaled by.
      final scale = kiloScale(weightsInKg: <double>[3.2, 3.2]);

      expect(labelsOf(scale), <String>['3.2', '3.21']);
      expectAscending(scale);
      expectSpans(scale, <double>[3.2, 3.2]);
    });

    test(
      'a weight typed in grams into the kilogram box still prints marks',
      () {
        // The form has no maximum, so 430 g arrives as 430 kg and the axis is asked for
        // two orders of magnitude more than the ladder was cut for. The marks are then
        // thinned by whole steps rather than running off the end of it: the buyer's page
        // gets every-one-hundred-kilograms, not a smear of a hundred labels.
        final scale = kiloScale(weightsInKg: <double>[3.1, 430]);

        expect(labelsOf(scale), <String>[
          '0',
          '100',
          '200',
          '300',
          '400',
          '450',
        ]);
        expect(scale.ticks.length, lessThanOrEqualTo(6));
        expectAscending(scale);
        expectSpans(scale, <double>[3.1, 430]);
      },
    );

    test(
      'a weigh-in a hair under a whole step is not cut off by the first mark',
      () {
        // `min * scale / unit` rounds to the nearest double before it is floored, and
        // a weight one ulp below a mark can round up onto it — leaving the lightest
        // weigh-in outside the box the grid drew. No weight the form can store sits
        // there (measured: the guard never runs on the ledger's own values), but the
        // enclosure is what the axis promises, so the promise is pinned with the one
        // input that used to break it.
        final scale = kiloScale(weightsInKg: <double>[1.8499999999999999, 1.9]);

        expect(labelsOf(scale), <String>['1.84', '1.86', '1.88', '1.9']);
        expectAscending(scale);
        expectSpans(scale, <double>[1.8499999999999999, 1.9]);
      },
    );

    test(
      'the rules every input has to answer, over the shapes a ledger makes',
      () {
        // A hand-derived label list proves one input; the page is built from whatever
        // the breeder typed. These are the three things that hold for all of them:
        // the marks enclose the data, no two share a value, and every mark has the
        // word it is keyed by.
        const List<List<double>> weights = <List<double>>[
          <double>[0.43, 0.43, 0.45],
          <double>[0.5, 0.9],
          <double>[2.5, 3.0],
          <double>[3.01, 3.04],
          <double>[3.2, 3.2],
          <double>[16, 22, 29],
          <double>[0.43, 5.5, 19.75, 35.2],
          <double>[60, 75, 90, 110],
          <double>[3.1, 430],
          <double>[0.43, 5000],
          <double>[1.8499999999999999, 1.9],
          <double>[3.6999999999999997, 3.75],
        ];
        const List<List<double>> ages = <List<double>>[
          <double>[0, 30, 61, 92],
          <double>[5, 400, 700, 900],
          <double>[30, 400],
          <double>[1095, 1200],
          <double>[5, 1460],
          <double>[988, 1009, 1012],
          <double>[40, 45],
          <double>[100, 100],
          <double>[0, 100000],
        ];

        for (final List<double> kilos in weights) {
          final scale = kiloScale(weightsInKg: kilos);
          expect(scale.ticks.length, lessThanOrEqualTo(6));
          expectAscending(scale);
          expectSpans(scale, kilos);
          for (final GrowthTick tick in scale.ticks) {
            expect(scale.format(tick.value), tick.label);
          }
        }
        for (final List<double> days in ages) {
          final scale = monthScale(agesInDays: days);
          expect(scale.ticks.length, lessThanOrEqualTo(6));
          expectAscending(scale);
          expectSpans(scale, days);
          for (final GrowthTick tick in scale.ticks) {
            expect(scale.format(tick.value), tick.label);
          }
        }
      },
    );
  });

  group('the rules of an axis, over records nobody picked', () {
    // Every case above is one a reviewer could think of and write down. The page is
    // built from whatever gets typed, and the two promises `growth_axis.dart` makes
    // — no more than six marks, and the marks enclosing the data — are said about
    // *every* input. They were checked over ~210,000 pairs on a laptop before the
    // algorithm was pushed; this is that sweep, kept, so the next edit to the stride
    // or the ladder is caught by CI rather than by a buyer's printed page.
    void expectEveryRule(GrowthScale scale, List<double> measured) {
      expect(
        scale.ticks.length,
        lessThanOrEqualTo(6),
        reason:
            'the axis of $measured prints more marks than the page has room for',
      );
      expectAscending(scale);
      expectSpans(scale, measured);
      for (final GrowthTick tick in scale.ticks) {
        expect(tick.label, isNotEmpty);
        expect(
          scale.format(tick.value),
          tick.label,
          reason: 'a mark with no word of its own prints a blank',
        );
      }
    }

    test('ages from one day old to past any living dog', () {
      final random = Random(_sweepSeed);
      for (var run = 0; run < _sweepRuns; run++) {
        final int points = 1 + random.nextInt(4);
        final ages = <double>[
          for (var i = 0; i < points; i++) random.nextDouble() * _oldestAgeDays,
        ];

        final scale = monthScale(agesInDays: ages);
        expectEveryRule(scale, ages);
        for (final GrowthTick tick in scale.ticks) {
          // The word under a mark is the age it sits at, in months. The defect that
          // first reached paper was a label that said something other than where the
          // mark was, so the pair is asserted rather than the two halves.
          expect(
            double.parse(tick.label) * meanDaysPerMonth,
            tick.value,
            reason:
                'the label ${tick.label} does not stand at that many months',
          );
        }
      }
    });

    test('weights on the ledger\'s own gram lattice, and past it', () {
      final random = Random(_sweepSeed);
      for (var run = 0; run < _sweepRuns; run++) {
        final int points = 1 + random.nextInt(4);
        final kilos = <double>[
          // Even runs are the only shape the app can store: a weigh-in is grams,
          // divided by a thousand on the way here. Odd runs are the kilogram box
          // filled in by hand, which has no maximum, so the thinning path runs.
          for (var i = 0; i < points; i++)
            if (run.isEven)
              random.nextInt(60000) / 1000.0
            else
              random.nextDouble() * _heaviestTypedKilos,
        ];

        final scale = kiloScale(weightsInKg: kilos);
        expectEveryRule(scale, kilos);
        for (final GrowthTick tick in scale.ticks) {
          expect(
            double.parse(tick.label),
            tick.value,
            reason:
                'the label ${tick.label} does not stand at that many kilograms',
          );
        }
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
