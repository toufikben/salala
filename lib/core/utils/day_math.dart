/// Calendar-day arithmetic, with no Flutter and no `intl`.
///
/// Everything in this app that answers "is it late?", "how many days?", "what
/// day is this?" has to count **days on a calendar**, not elapsed milliseconds.
/// A booster due today at local midnight is 16 hours in the past by lunchtime,
/// and a breeder reading "overdue" on a dose that is due today stops trusting
/// every other red word on the screen.
///
/// The two rules that keep this honest, both decided in `DECISIONS.md` (D28,
/// D31):
///
/// * a stored date is a *day*, so comparisons drop the time of day;
/// * a day moved by n days is `DateTime(y, m, d + n)`, never
///   `add(Duration(days: n))` — a day on which the clock shifts is 23 or 25
///   hours long, and 720 hours is not 30 days.
///
/// This file is separate from `date_utils.dart` because the models import it.
/// A model that reaches for `BuildContext` to decide whether a dose is late
/// would be a model no plain Dart test could run.
library;

/// The local calendar day [ms] falls on, as midnight of that day.
int dayStartMs(int ms) {
  final at = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(at.year, at.month, at.day).millisecondsSinceEpoch;
}

/// Whole calendar days from [fromMs] to [toMs]: negative when [fromMs] is still
/// ahead, zero when both instants fall on the same day.
int wholeDaysBetween(int fromMs, int toMs) {
  final from = dayStartMs(fromMs);
  final to = dayStartMs(toMs);
  // Both ends are local midnights, so the difference is a whole number of days
  // except across a clock change — where rounding absorbs the hour, which is
  // exactly the hour a breeder did not spend.
  return ((to - from) / 86400000).round();
}

/// Whether [dayMs] names a calendar day strictly earlier than [nowMs]'s.
///
/// This is the one question a due date answers: a dose due **today** is not
/// overdue, whatever the hour. A missing date never is.
bool isPastDay(int? dayMs, int nowMs) =>
    dayMs != null && wholeDaysBetween(dayMs, nowMs) > 0;

/// [day] moved by whole calendar days, in either direction.
DateTime shiftDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// [ms] moved by whole calendar days, keeping its time of day.
///
/// The time has to survive: a horizon counted from lunchtime and landing on
/// midnight loses the last half-day of its own window, and the dose that fell on
/// the final afternoon is exactly the one the breeder expected to see.
int addDays(int ms, int days) {
  final at = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(
    at.year,
    at.month,
    at.day + days,
    at.hour,
    at.minute,
    at.second,
    at.millisecond,
    at.microsecond,
  ).millisecondsSinceEpoch;
}
