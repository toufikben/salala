/// What the whole kennel adds up to, worked out apart from any screen.
///
/// A breeder with forty animals and six years of whelpings does not want a list
/// she can already see — she wants the four numbers she would otherwise count on
/// her fingers: how many live here, how many are breeding stock, how many puppies
/// this year, and what the handovers came to.
///
/// Two rules shape everything below, both of them about not lying with a number:
///
/// * **Money is never summed across currencies.** 2000 MAD and 2000 EUR are not
///   4000 of anything. The revenue comes back as one total per currency, and the
///   screen prints one line each.
/// * **A year is a calendar year, and a month is a calendar month.** Nothing here
///   divides milliseconds by 31 536 000 000: a whelping on 1 January belongs to
///   the new year whatever the clock did in between.
///
/// An animal that died is counted where it is, not where it was: `atHome` counts
/// who is here now, and `everRecorded` counts the ledger. The gap between the two
/// is the history a breeder is keeping, not an error to reconcile.
library;

import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../../data/models/placement.dart';

/// One currency's takings, and how many handovers made them.
///
/// The count is carried beside the total because a single row of 2500 and five
/// rows of 500 are the same number and a different business.
class RevenueByCurrency {
  const RevenueByCurrency({
    required this.currency,
    required this.total,
    required this.count,
  });

  /// Upper-cased, or the empty string for a handover with no currency typed.
  /// The empty string is kept rather than folded into a guess: a bare `2500` is
  /// a price whose unit nobody wrote down, and printing it as dollars would be
  /// the app inventing a fact.
  final String currency;
  final double total;
  final int count;
}

/// The kennel in five numbers.
class KennelStats {
  const KennelStats({
    required this.everRecorded,
    required this.atHome,
    required this.breedingStock,
    required this.males,
    required this.females,
    required this.whelpings,
    required this.puppiesRegistered,
    required this.puppiesThisYear,
    required this.thisYear,
    required this.revenue,
  });

  /// Every animal row the ledger holds, whatever became of them.
  final int everRecorded;

  /// The ones a dose reminder is still owed to: `status.isAtHome`.
  final int atHome;

  /// Females and males at home, because that is the number a breeder matches a
  /// mating against. Both count only animals still here.
  final int breedingStock;
  final int males;
  final int females;

  /// Whelpings with a date on file. An undated litter is a record of a litter,
  /// not of a season, and counting it as one would put a whelping in a year
  /// nobody chose.
  final int whelpings;

  /// Puppies born into a recorded litter, all years.
  final int puppiesRegistered;

  /// Puppies born in [thisYear], and the year the count is about — carried rather
  /// than read from the clock by the screen, so a test can ask about 2025.
  final int puppiesThisYear;
  final int thisYear;

  /// One entry per currency, biggest total first. Empty when nothing was sold.
  final List<RevenueByCurrency> revenue;

  /// Handovers on file, whatever they were priced at.
  int get placements => revenue.fold(0, (sum, row) => sum + row.count);

  bool get isEmpty => everRecorded == 0 && whelpings == 0;
}

/// Counts [animals], [litters] and [placements] into one summary.
///
/// Nothing is filtered out before counting except where a number would otherwise
/// mean two things at once: a litter with no whelping date has no year, so it is
/// counted in [KennelStats.whelpings] and not in [KennelStats.puppiesThisYear].
KennelStats kennelStats({
  required List<Animal> animals,
  required List<Litter> litters,
  required List<Placement> placements,
  required int nowMs,
}) {
  final year = DateTime.fromMillisecondsSinceEpoch(nowMs).year;

  var atHome = 0;
  var breeding = 0;
  var males = 0;
  var females = 0;
  for (final animal in animals) {
    if (!animal.status.isAtHome) continue;
    atHome++;
    if (animal.isBreedingStock) breeding++;
    if (animal.sex == Sex.male) males++;
    if (animal.sex == Sex.female) females++;
  }

  var whelpings = 0;
  for (final litter in litters) {
    final born = litter.whelpingDate;
    if (born == null) continue;
    whelpings++;
  }

  // Puppies are counted from the herd, not from a litter's own list: a puppy
  // registered by hand outside a whelping, or one that arrived by pack from
  // another phone, is still a puppy this kennel recorded, and a count built from
  // litters would miss it. `litterId` is the marker — it is the field that says
  // "this animal was born into a whelping on file".
  var puppies = 0;
  var puppiesThisYear = 0;
  for (final animal in animals) {
    final born = animal.birthDate;
    if (born == null) continue;
    if (animal.litterId != null) puppies++;
    // A puppy born this year is part of this year's work whatever its status:
    // one already placed is a handover, not a dog that was never here.
    if (DateTime.fromMillisecondsSinceEpoch(born).year == year) {
      puppiesThisYear++;
    }
  }

  final byCurrency = <String, (double, int)>{};
  for (final placement in placements) {
    final price = placement.price;
    if (price == null) continue;
    final currency = (placement.currency ?? '').trim().toUpperCase();
    final current = byCurrency[currency];
    byCurrency[currency] = (
      (current?.$1 ?? 0) + price,
      (current?.$2 ?? 0) + 1,
    );
  }
  final revenue = <RevenueByCurrency>[
    for (final entry in byCurrency.entries)
      RevenueByCurrency(
        currency: entry.key,
        total: entry.value.$1,
        count: entry.value.$2,
      ),
  ]..sort((a, b) {
    final byTotal = b.total.compareTo(a.total);
    // A stable tie-break on the currency itself: two currencies can total the
    // same, and a list that reordered them between two builds would read as the
    // totals having changed.
    return byTotal != 0 ? byTotal : a.currency.compareTo(b.currency);
  });

  return KennelStats(
    everRecorded: animals.length,
    atHome: atHome,
    breedingStock: breeding,
    males: males,
    females: females,
    whelpings: whelpings,
    puppiesRegistered: puppies,
    puppiesThisYear: puppiesThisYear,
    thisYear: year,
    revenue: revenue,
  );
}

/// One animal whose birthday is close.
class BirthdaySoon {
  const BirthdaySoon({
    required this.animalId,
    required this.name,
    required this.days,
    required this.turning,
  });

  final String animalId;
  final String name;

  /// Whole days from today to the birthday, zero when it is today.
  final int days;

  /// The age she turns, in years. One for a first birthday, which is the one a
  /// breeder photographs.
  final int turning;
}

/// Birthdays in the next [withinDays], soonest first.
///
/// A birthday is the one date a year that is worth saying out loud about an
/// animal who is doing fine, and it is also the cheapest way for the app to
/// notice the ledger is alive. A dog that died is not celebrated — that would be
/// the app forgetting the one fact a breeder never forgets — so only animals at
/// home are considered, and an animal with no birth date is simply absent.
///
/// The comparison is on month and day, never on the year: an animal born in 2019
/// has a birthday in 2026 like everybody else. 29 February is answered honestly
/// — in a common year it falls on 1 March, which is what a breeder who was born
/// on a leap day is used to being told.
List<BirthdaySoon> birthdaysSoon(
  List<Animal> animals, {
  required int nowMs,
  int withinDays = 14,
}) {
  final today = DateTime.fromMillisecondsSinceEpoch(nowMs);
  final start = DateTime(today.year, today.month, today.day);
  final found = <BirthdaySoon>[];

  for (final animal in animals) {
    if (!animal.status.isAtHome) continue;
    final born = animal.birthDate;
    if (born == null) continue;
    final date = DateTime.fromMillisecondsSinceEpoch(born);
    if (date.isAfter(start)) continue;

    // This year's birthday if it has not gone by, otherwise next year's: a
    // breeder opening the app on 2 January should see the puppy's birthday in
    // eleven months only if nothing else is coming, which `withinDays` decides.
    var next = _birthdayIn(start.year, date);
    if (next.isBefore(start)) next = _birthdayIn(start.year + 1, date);
    final days = next.difference(start).inDays;
    if (days > withinDays) continue;

    found.add(
      BirthdaySoon(
        animalId: animal.id,
        name: animal.name,
        days: days,
        turning: next.year - date.year,
      ),
    );
  }

  found.sort((a, b) {
    final byDays = a.days.compareTo(b.days);
    return byDays != 0 ? byDays : a.name.compareTo(b.name);
  });
  return found;
}

/// [born]'s month and day, placed in [year].
///
/// A 29 February birthday in a common year lands on 1 March rather than being
/// dropped: `DateTime(2026, 2, 29)` silently becomes 1 March in Dart, which is
/// the answer wanted and the reason this is a named function rather than a
/// `try` somewhere.
DateTime _birthdayIn(int year, DateTime born) =>
    DateTime(year, born.month, born.day);
