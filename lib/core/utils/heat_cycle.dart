/// When a dam's next heat is likely, from the two heats already in her record.
///
/// This is the one piece of arithmetic in the app that is a *guess*, and the
/// whole file is shaped by that. A heat cycle is 5–11 months apart in a dog and
/// anything from 2 weeks to 4 months in a cat, so a screen that printed a date
/// would be wrong often enough to stop being read. What it prints instead is a
/// window, and the window widens with every uncertainty in the record:
///
/// * one heat on file → nothing. A single observation says the cycle exists and
///   says nothing about its length.
/// * two heats → the observed gap, and the window is the gap itself plus and
///   minus one standard interval, because two observations can agree perfectly
///   and still be a coincidence.
/// * three or more → the mean of the gaps, and a window narrow enough to plan a
///   mating around.
///
/// Nothing here is species-specific arithmetic on a constant: the numbers come
/// from the dam's own record or they do not come at all. A breeder mating a
/// species this file has never heard of gets the same treatment as a dog,
/// because the interval it reasons about is the one she typed.
library;

import '../../data/models/animal.dart';
import '../../data/models/litter.dart';

/// Days in the window a heat may fall inside, either side of the estimate.
///
/// Twenty-one days, not seven: a dog's cycle genuinely varies by a fortnight
/// between bitches and between one season and the next, so a tighter window
/// would be a more precise lie. Widening it costs a breeder nothing — the screen
/// doubles as a reminder to start watching — while narrowing it costs her a
/// missed mating.
const int heatWindowDays = 21;

/// What the planner knows about one dam's cycle.
class HeatForecast {
  const HeatForecast({
    required this.observedCycles,
    required this.averageGapDays,
    required this.earliest,
    required this.latest,
    required this.estimated,
    required this.confidence,
  });

  /// How many gaps between heats the record actually contains, not how many
  /// heats: two heats is one gap, three heats is two.
  final int observedCycles;

  final int averageGapDays;

  /// The window, as unix milliseconds, around [estimated].
  final int earliest;
  final int latest;
  final int estimated;

  /// How much weight the estimate deserves, as a word rather than a percent.
  ///
  /// A number here would be an invention: nothing in this record supports
  /// "72% likely", and printing it would make a guess look measured.
  final HeatConfidence confidence;
}enum HeatConfidence {
  /// Two heats: one observed gap, and a window wide enough to hold a surprise.
  thin,

  /// Three or more heats: the mean of at least two gaps, and a window a breeder
  /// can plan a mating around.
  steady,
}

/// The litters of one dam, newest mating first, whichever species she is.
///
/// A mating is only useful to this file when it has a date, because the cycle
/// interval is measured between matings — a litter with no mating date records
/// that a whelping happened, not when the season that produced it began.
List<Litter> heatsOf(List<Litter> litters, String damId) {
  final heats = <Litter>[
    for (final litter in litters)
      if (litter.damId == damId && litter.matingDate != null) litter,
  ];
  heats.sort((a, b) => b.matingDate!.compareTo(a.matingDate!));
  return heats;
}

/// The forecast for one dam, or null when the record cannot support one.
///
/// Null is a real answer and the screen says so in words. A dam with no mating
/// on file, or with one, has a cycle nobody has observed twice, and an app that
/// guessed "every six months" from a constant would be reading a breed standard
/// aloud instead of reading this breeder's record.
HeatForecast? forecastHeat(List<Litter> litters, Animal dam) {
  if (dam.sex != Sex.female) return null;
  final heats = heatsOf(litters, dam.id);
  if (heats.length < 2) return null;

  // Newest first, so a gap is `older - newer` read backwards. Kept as a list of
  // positive numbers rather than a difference of indices, because the arithmetic
  // below is where a sign slip would become a window in the past.
  final gaps = <int>[];
  for (var i = 0; i < heats.length - 1; i++) {
    final newer = heats[i].matingDate!;
    final older = heats[i + 1].matingDate!;
    final days = _wholeDaysBetween(older, newer);
    // Zero or negative means two matings recorded on one day, which is one heat
    // and should not be averaged in as a cycle of length nothing.
    if (days > 0) gaps.add(days);
  }
  if (gaps.isEmpty) return null;

  final average = (gaps.reduce((a, b) => a + b) / gaps.length).round();
  final last = heats.first.matingDate!;
  final estimate = _addDays(last, average);

  // A window of one interval either side for two observations, and the fixed
  // [heatWindowDays] once the mean rests on more than one gap. The wide case is
  // the honest one: one gap can be a coincidence, and a breeder who plans a
  // mating inside a fortnight of a guess has planned nothing.
  final slack = gaps.length == 1 ? average : heatWindowDays;

  return HeatForecast(
    observedCycles: gaps.length,
    averageGapDays: average,
    earliest: _addDays(estimate, -slack),
    latest: _addDays(estimate, slack),
    estimated: estimate,
    confidence: gaps.length == 1 ? HeatConfidence.thin : HeatConfidence.steady,
  );
}

/// Calendar days between two local midnights, rounded for daylight saving.
int _wholeDaysBetween(int fromMs, int toMs) {
  final from = DateTime.fromMillisecondsSinceEpoch(fromMs);
  final to = DateTime.fromMillisecondsSinceEpoch(toMs);
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return (b.difference(a).inHours / 24).round();
}

/// [ms] moved by [days] calendar days, not milliseconds.
///
/// The distinction matters at a daylight-saving boundary: adding 63 * 86 400 000
/// milliseconds to a date in March lands an hour into the wrong day, and a
/// breeder counting on her fingers gets the day she expects.
int _addDays(int ms, int days) {
  final day = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(day.year, day.month, day.day + days).millisecondsSinceEpoch;
}
