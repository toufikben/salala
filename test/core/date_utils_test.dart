import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/core/utils/date_utils.dart';

/// Which numeral system a date is written in, per language.
///
/// The instant is pinned rather than read from the machine: this is about the
/// shape of the string, and a test that asked what year it was would fail its
/// own point at midnight on 31 December.
void main() {
  setUpAll(() => initializeDateFormatting());

  final ms = DateTime(2026, 10, 6).millisecondsSinceEpoch;
  final arabicIndicDigits = RegExp(r'[٠-٩]');

  test('Arabic keeps its own month names and takes Latin digits', () {
    final day = formatDayFor('ar', ms);

    expect(day, contains('2026'));
    expect(day, contains('6'));
    expect(
      arabicIndicDigits.hasMatch(day),
      isFalse,
      reason:
          'D21: a breeder reads a ledger date off a paper certificate typed '
          'in Latin digits, and the weight on the same row is Latin already',
    );
  });

  test('English and French have nothing to convert', () {
    for (final tag in <String>['en', 'fr']) {
      final day = formatDayFor(tag, ms);
      expect(day, contains('2026'));
      expect(arabicIndicDigits.hasMatch(day), isFalse);
    }
  });

  test('a record with no date renders no text at all', () {
    expect(formatDayFor('ar', null), '');
    expect(formatDayFor('en', null), '');
  });

  group('shiftDays', () {
    test('a month boundary lands where a calendar points', () {
      expect(shiftDays(DateTime(2027, 1, 2), -30), DateTime(2026, 12, 3));
      expect(shiftDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    });

    test('the hour a row was stored at is not part of the count', () {
      // D31: a due date is a date. Counting back from 23:30 has to reach the same
      // day as counting back from 08:00, or a reminder's morning would be built
      // off whichever hour the write happened to carry.
      expect(
        shiftDays(DateTime(2027, 1, 2, 23, 30), -30),
        DateTime(2026, 12, 3),
      );
    });

    test('February is counted in the year the row belongs to', () {
      expect(shiftDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
      expect(shiftDays(DateTime(2024, 3, 1), -1), DateTime(2024, 2, 29));
    });
  });
}
