import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// [formatDay] for work that outlives the widget that started it.
///
/// A launch-time reminder rebuild is still running when its screen can be
/// popped, and reading a `BuildContext` after an `await` is how a disposed
/// widget gets touched. The language tag is a string; take it and pass it on.
String formatDayFor(String localeTag, int? epochMs) {
  if (epochMs == null) return '';
  return _latinDigits(
    DateFormat.yMMMd(localeTag)
        .format(DateTime.fromMillisecondsSinceEpoch(epochMs)),
  );
}

/// A date a reader can line up against a paper certificate, or the words for
/// "never written down".
///
/// [formatDayFor] answers an empty string, which is right on a screen where the
/// row itself carries the missing field and wrong on a printed page: a blank cell
/// reads as something the app withheld, so the gap in the record has to be named
/// out loud. Both documents ask, so this lives beside the formatter rather than
/// inside one of them.
String formatDayOrUnknown(
  AppLocalizations l10n,
  String localeTag,
  int? epochMs,
) {
  final day = formatDayFor(localeTag, epochMs);
  return day.isEmpty ? l10n.valueUnknown : day;
}

/// Every digit Salala prints is a Latin one, in every language (D21).
///
/// `intl` gives Arabic its CLDR-default Arabic-Indic digits, and `formatWeight`
/// writes ASCII, so a row would otherwise read "18.50 كغ" next to
/// "٥ أكتوبر ٢٠٢٦". A breeder checks a date against a paper certificate typed
/// in Latin digits, so the digits that have to move are the date's. English and
/// French pass through untouched — there is nothing to translate.
String _latinDigits(String text) {
  final buffer = StringBuffer();
  for (final unit in text.codeUnits) {
    buffer.writeCharCode(
      unit >= 0x0660 && unit <= 0x0669 ? unit - 0x0660 + 0x30 : unit,
    );
  }
  return buffer.toString();
}

/// Localised day for record rows. `initializeDateFormatting()` runs in `main()`
/// so non-English locales do not throw at first use.
String formatDay(BuildContext context, int? epochMs) =>
    formatDayFor(Localizations.localeOf(context).toString(), epochMs);

/// A day-of-month/month/year triple is what a breeder reads off a paper
/// certificate, so forms exchange calendar parts rather than ISO strings.
DateTime? dayFromMs(int? epochMs) =>
    epochMs == null ? null : DateTime.fromMillisecondsSinceEpoch(epochMs);

int msFromDay(DateTime day) =>
    DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;

/// Whole calendar days from [fromMs] to [toMs]: negative when [fromMs] is still
/// ahead, zero when both instants fall on the same day.
///
/// The dates a breeder reads off paper — a due booster, a certificate's validity,
/// a whelping day — are stored at local midnight, so an *instant* difference says
/// the morning has already gone by and reports a dose due today as one day late.
/// Counting the dates rather than the elapsed milliseconds is the same arithmetic
/// the animal's card and the herd's agenda have to agree on (D28), which is why it
/// lives here rather than in either of them.
int wholeDaysBetween(int fromMs, int toMs) {
  final from = DateTime.fromMillisecondsSinceEpoch(fromMs);
  final to = DateTime.fromMillisecondsSinceEpoch(toMs);
  final a = DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
  final b = DateTime(to.year, to.month, to.day).millisecondsSinceEpoch;
  return ((b - a) / 86400000).round();
}

/// [day] moved by whole calendar days, in either direction.
///
/// The other way to write this is `day.add(Duration(days: n))`, and that counts
/// *hours*: on a day the clock shortens or lengthens — Morocco steps between
/// UTC+1 and UTC+0 for Ramadan — 720 hours lands on the day before or after the
/// one a breeder would point at on a paper calendar. D31 says a due date is a
/// date, so a reminder booked thirty days ahead of one, and the horizon a launch
/// rebuilds alarms out of, are both counted here off the day number.
DateTime shiftDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// Whether a whelping's three dates tell a story that cannot have happened.
enum LitterDateProblem { none, whelpingBeforeMating, weaningBeforeWhelping }

/// Which story a whelping's dates tell, if any that cannot have happened: a
/// birth before the mating it came from, or a weaning before the litter was born.
///
/// Refused because the ledger is read back through them: a litter's PDF prints
/// the mating and the whelping side by side, and every puppy's birthday is the
/// whelping date, so a slipped pair does not sit unnoticed — it becomes the
/// herd's age arithmetic. A missing date is not a contradiction, and two dates
/// on the same day are not one either: the picker is a day picker, and a mating
/// recorded on the whelping day is imprecise rather than impossible.
LitterDateProblem litterDateProblem({
  required int? matingDateMs,
  required int? whelpingDateMs,
  required int? weaningDateMs,
}) {
  if (_isDayBefore(whelpingDateMs, matingDateMs)) {
    return LitterDateProblem.whelpingBeforeMating;
  }
  if (_isDayBefore(weaningDateMs, whelpingDateMs)) {
    return LitterDateProblem.weaningBeforeWhelping;
  }
  return LitterDateProblem.none;
}

/// The date a row measures *from* and the date it measures *to*, the wrong way
/// round: a booster due before the dose that earned it, a certificate expiring
/// before the test it certifies.
///
/// One rule for both shapes, because both are the same failure: a date that is
/// overdue against its own anchor never clears, so the row sits in the herd's
/// agenda as overdue forever and trains the breeder to ignore the one screen it
/// exists to be looked at. A certificate that expired before the screening it
/// certifies is not a fact at all, and the transfer pack prints it as one.
///
/// One predicate, two sentences: each form names the field to fix, which is the
/// reason **D36** keeps rules like this on the screen instead of in a constraint.
bool measuredDatePrecedesAnchor({
  required int? anchorMs,
  required int? measuredMs,
}) => _isDayBefore(measuredMs, anchorMs);

/// A dated fact about one animal, stamped before that animal existed.
///
/// Every date in this app is picked from a window measured back from today —
/// five years for a weigh-in, fifteen for a symptom, a test, a visit — and the
/// window has to be that wide, because a breeder moving a paper ledger in needs
/// to reach 2011. So the picker can land on a day before the animal was born,
/// and nothing else notices: the triage rules read the *age* of a sign, so a
/// symptom dated three years back keeps a vomiting puppy off the alarm; a
/// weigh-in dated before birth plots growth on days that never happened; a dose
/// dated there books its booster against an animal that was not alive. The
/// failure is a mistyped year, and the year is the field a mistype lands on
/// hardest because it is the one the picker scrolls rather than taps.
///
/// Checked at the form and not in the dao for the reason **D36** gives for the
/// litter pair: the transfer pack restore writes these same rows through the
/// same dao, and it has to stay permissive — a pack from a paper ledger can
/// legitimately carry a birth date the breeder is still correcting, and a
/// restore that refuses the whole transaction naming no field is the failure
/// D36 was written to avoid.
bool recordPrecedesBirth({required int? recordMs, required int? birthMs}) =>
    _isDayBefore(recordMs, birthMs);

bool _isDayBefore(int? earlierMs, int? laterMs) {
  if (earlierMs == null || laterMs == null) return false;
  final a = dayFromMs(earlierMs)!;
  final b = dayFromMs(laterMs)!;
  return DateTime(
    a.year,
    a.month,
    a.day,
  ).isBefore(DateTime(b.year, b.month, b.day));
}
