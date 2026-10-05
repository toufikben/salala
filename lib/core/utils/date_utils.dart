import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

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
