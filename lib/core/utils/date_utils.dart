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
