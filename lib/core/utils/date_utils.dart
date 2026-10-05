import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// [formatDay] for work that outlives the widget that started it.
///
/// A launch-time reminder rebuild is still running when its screen can be
/// popped, and reading a `BuildContext` after an `await` is how a disposed
/// widget gets touched. The language tag is a string; take it and pass it on.
String formatDayFor(String localeTag, int? epochMs) {
  if (epochMs == null) return '';
  return DateFormat.yMMMd(localeTag)
      .format(DateTime.fromMillisecondsSinceEpoch(epochMs));
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
