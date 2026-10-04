import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Localised day for record rows. `initializeDateFormatting()` runs in `main()`
/// so non-English locales do not throw at first use.
String formatDay(BuildContext context, int? epochMs) {
  if (epochMs == null) return '';
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale)
      .format(DateTime.fromMillisecondsSinceEpoch(epochMs));
}

/// A day-of-month/month/year triple is what a breeder reads off a paper
/// certificate, so forms exchange calendar parts rather than ISO strings.
DateTime? dayFromMs(int? epochMs) =>
    epochMs == null ? null : DateTime.fromMillisecondsSinceEpoch(epochMs);

int msFromDay(DateTime day) =>
    DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
