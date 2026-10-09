/// The two axes of the growth curve, worked out apart from the page.
///
/// A `pdf` axis is drawn through the embedded font's glyph ids, so a test over the
/// bytes of a document cannot read a tick label back — which is exactly how the
/// first version of this chart shipped: it handed the axis the raw set of ages in
/// days, and a buyer's printed page said `988.0 1009.0 1012.0` under a curve
/// instead of saying anything about months. Here the marks are chosen, and here
/// they are checked.
///
/// Age is in months because that is the unit a breeder answers in — "she was four
/// months and had already doubled" — and weight in kilograms because that is the
/// unit the form asks for. Both scales are made of whole steps that *contain* the
/// data: the axis endpoints are what a point is positioned against, so a domain cut
/// to the first and last measurement would put the two points nobody ticked outside
/// the plotted box.
library;

/// Gregorian mean month: 365.2425 days over twelve.
///
/// Calendar months would be truer to a birthday, and would have to answer what "one
/// month after January 31st" is before the axis could be laid out. The difference
/// between the two is under two days on an axis whose whole width is a printed
/// centimetre and a half — the curve is read for its shape, not to the day.
const double meanDaysPerMonth = 365.2425 / 12;

/// One mark on an axis: where it sits in the plotted unit, and what it says.
class GrowthTick {
  const GrowthTick(this.value, this.label);

  final double value;
  final String label;
}

/// An axis's marks, and the words for them.
class GrowthScale {
  GrowthScale(this.ticks)
    : labels = <double, String>{
        for (final GrowthTick tick in ticks) tick.value: tick.label,
      };

  final List<GrowthTick> ticks;

  final Map<double, String> labels;

  /// The values [labels] is keyed by, in the order `pw.FixedAxis` insists on.
  List<double> get values => <double>[
    for (final GrowthTick tick in ticks) tick.value,
  ];

  /// The words for one of [values].
  ///
  /// `pw.FixedAxis` only ever asks for a value it was handed, so a miss is this file
  /// disagreeing with itself about its own keys — worth a crash on a builder's
  /// screen rather than a blank printed on a document somebody keeps.
  String format(num value) => labels[value.toDouble()]!;
}

/// Marks in whole months of age, spanning every age measured.
///
/// [agesInDays] is age in days since birth, which is what the curve plots; the
/// chart is skipped before this is reached when there is no birth date, or fewer
/// than two distinct ages to place.
GrowthScale monthScale({required List<double> agesInDays, int maxTicks = 6}) {
  var min = agesInDays.first;
  var max = agesInDays.first;
  for (final double age in agesInDays) {
    if (age < min) min = age;
    if (age > max) max = age;
  }

  final first = (min / meanDaysPerMonth).floor();
  var last = (max / meanDaysPerMonth).ceil();
  // Two weigh-ins inside one month would otherwise give one mark, and a single mark
  // is an axis whose whole span is zero — the divisor the points are scaled by.
  if (last <= first) last = first + 1;

  var step = _monthSteps.last;
  for (final int candidate in _monthSteps) {
    if (_months(first, last, candidate) <= maxTicks) {
      step = candidate;
      break;
    }
  }

  final ticks = <GrowthTick>[
    for (var month = first; month <= last; month += step)
      GrowthTick(month * meanDaysPerMonth, '$month'),
  ];
  // A whole step short of the oldest month measured would leave that weigh-in past
  // the edge of the box, so the range always ends where it has to.
  final end = last * meanDaysPerMonth;
  if (ticks.last.value < end) ticks.add(GrowthTick(end, '$last'));
  return GrowthScale(ticks);
}

/// Marks in kilograms, spanning every weight measured.
///
/// The arithmetic is done in whole hundredths, tenths or units of a kilogram
/// rather than in fractions of a double: `3.01 / 0.01` comes out as 300.9999999,
/// and a mark placed by that quotient is not the mark the step says it is. The
/// invariant the tests hold to is that the marks *enclose* the weigh-ins, every
/// label is what its mark is, and no two marks share a value.
GrowthScale kiloScale({required List<double> weightsInKg, int maxTicks = 6}) {
  var min = weightsInKg.first;
  var max = weightsInKg.first;
  for (final double kilo in weightsInKg) {
    if (kilo < min) min = kilo;
    if (kilo > max) max = kilo;
  }

  final step = _kiloStep(min, max, maxTicks);
  final digits = _decimals(step);
  final scale = _scales[digits];
  final unit = (step * scale).round();
  var (first, last) = _kiloRange(min, max, step);
  // One mark is an axis whose whole width is zero, and the points are scaled by it.
  if (last < first + 1) last = first + 1;

  return GrowthScale(<GrowthTick>[
    for (var i = first; i <= last; i++)
      GrowthTick(i * unit / scale, _trim(i * unit / scale, digits)),
  ]);
}

const List<int> _monthSteps = <int>[1, 2, 3, 4, 6, 12, 24, 36, 60, 120];

/// The steps a weight axis may be cut into, finest first.
///
/// A 430-gram newborn and a 35-kilogram dam are the same axis two orders of
/// magnitude apart, so the step is chosen rather than fixed: the finest one whose
/// marks still fit the page.
const List<double> _kiloSteps = <double>[
  0.01,
  0.02,
  0.05,
  0.1,
  0.2,
  0.5,
  1,
  2,
  5,
  10,
  20,
  50,
];

/// How many places [step] can put after the point, and so how far the ledger's
/// kilograms must be shifted to be counted in whole numbers.
int _decimals(double step) {
  if (step >= 1) return 0;
  return step >= 0.1 ? 1 : 2;
}

const List<double> _scales = <double>[1, 10, 100];

double _kiloStep(double min, double max, int maxTicks) {
  for (final double step in _kiloSteps) {
    final (first, last) = _kiloRange(min, max, step);
    if (last - first + 1 <= maxTicks) return step;
  }
  return _kiloSteps.last;
}

/// The first and last whole-step marks enclosing both weights, in steps.
///
/// One conversion, not two: `(min * scale).floor()` on its own is a whole number
/// only when the shift lands true, and a weight like `0.43` shifted by ten comes
/// out `4.2999999`. Dividing before rounding keeps the mark on the step it is
/// named for, and the floor and ceil directions are what make the pair enclose
/// the data rather than cut into it.
(int, int) _kiloRange(double min, double max, double step) {
  final scale = _scales[_decimals(step)];
  final unit = (step * scale).round();
  final first = (min * scale / unit).floor();
  final last = (max * scale / unit).ceil();
  return (first, last);
}

/// How many marks a month step puts down, counting the one that closes the range.
int _months(int first, int last, int step) =>
    ((last - first) / step).ceil() + 1;

String _trim(double value, int decimals) {
  final text = value.toStringAsFixed(decimals);
  if (!text.contains('.')) return text;
  return text.replaceAll(RegExp(r'\.?0+$'), '');
}
