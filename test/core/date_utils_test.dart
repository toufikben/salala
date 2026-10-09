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

  group('litterDateProblem', () {
    int day(int year, int month, int dayOfMonth, {int hour = 0}) =>
        DateTime(year, month, dayOfMonth, hour).millisecondsSinceEpoch;

    test('a whelping before the mating it came from is named', () {
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 6, 1),
          whelpingDateMs: day(2026, 1, 1),
          weaningDateMs: null,
        ),
        LitterDateProblem.whelpingBeforeMating,
      );
    });

    test('a weaning before the litter was born is named', () {
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 1, 1),
          whelpingDateMs: day(2026, 3, 1),
          weaningDateMs: day(2026, 2, 1),
        ),
        LitterDateProblem.weaningBeforeWhelping,
      );
    });

    test('the pairs that line up are not a problem', () {
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 1, 1),
          whelpingDateMs: day(2026, 3, 1),
          weaningDateMs: day(2026, 5, 1),
        ),
        LitterDateProblem.none,
      );
    });

    test('a missing date is not a contradiction', () {
      // The form makes every three optional, so this is the common case rather
      // than an edge one: a whelping with no mating recorded is a Tuesday
      // evening remembered, not a story that cannot have happened.
      expect(
        litterDateProblem(
          matingDateMs: null,
          whelpingDateMs: day(2026, 3, 1),
          weaningDateMs: null,
        ),
        LitterDateProblem.none,
      );
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 6, 1),
          whelpingDateMs: null,
          weaningDateMs: day(2026, 1, 1),
        ),
        LitterDateProblem.none,
        reason:
            'with no whelping to sit between them, the outer two say nothing',
      );
    });

    test('two dates on one day are imprecise, not impossible', () {
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 3, 1),
          whelpingDateMs: day(2026, 3, 1),
          weaningDateMs: day(2026, 3, 1),
        ),
        LitterDateProblem.none,
      );
    });

    test('the hour a row was stored at does not make a day earlier', () {
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 3, 1, hour: 23),
          whelpingDateMs: day(2026, 3, 1),
          weaningDateMs: null,
        ),
        LitterDateProblem.none,
      );
    });

    test('a year boundary is a day before, not a larger number', () {
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 1, 1),
          whelpingDateMs: day(2025, 12, 31),
          weaningDateMs: null,
        ),
        LitterDateProblem.whelpingBeforeMating,
      );
    });

    test('a litter dated backwards at both ends is refused for the first thing', () {
      // Which sentence a breeder reads decides what they fix first, so the
      // precedence is a decision rather than an accident of the checks' order.
      expect(
        litterDateProblem(
          matingDateMs: day(2026, 6, 1),
          whelpingDateMs: day(2026, 1, 1),
          weaningDateMs: day(2025, 1, 1),
        ),
        LitterDateProblem.whelpingBeforeMating,
      );
    });
  });

  group('measuredDatePrecedesAnchor', () {
    int day(int year, int month, int dayOfMonth) =>
        DateTime(year, month, dayOfMonth).millisecondsSinceEpoch;

    test('a booster due before the dose that earned it is refused', () {
      expect(
        measuredDatePrecedesAnchor(
          anchorMs: day(2026, 5, 1),
          measuredMs: day(2026, 4, 1),
        ),
        isTrue,
      );
    });

    test(
      'a certificate expiring before the screening it certifies is refused',
      () {
        expect(
          measuredDatePrecedesAnchor(
            anchorMs: day(2026, 5, 1),
            measuredMs: day(2025, 11, 30),
          ),
          isTrue,
        );
      },
    );

    test(
      'the measured date landing on its anchor day is not a contradiction',
      () {
        expect(
          measuredDatePrecedesAnchor(
            anchorMs: day(2026, 5, 1),
            measuredMs: day(2026, 5, 1),
          ),
          isFalse,
        );
      },
    );

    test('a row with no measured date has nothing to contradict', () {
      expect(
        measuredDatePrecedesAnchor(anchorMs: day(2026, 5, 1), measuredMs: null),
        isFalse,
      );
      expect(
        measuredDatePrecedesAnchor(anchorMs: null, measuredMs: day(2026, 5, 1)),
        isFalse,
      );
    });
  });

  group('recordPrecedesBirth', () {
    int day(int year, int month, int dayOfMonth, {int hour = 0}) =>
        DateTime(year, month, dayOfMonth, hour).millisecondsSinceEpoch;

    test('a record dated before the animal was born is refused', () {
      expect(
        recordPrecedesBirth(
          recordMs: day(2026, 3, 1),
          birthMs: day(2026, 5, 1),
        ),
        isTrue,
      );
    });

    test('the day of the birth itself is a legal day to record on', () {
      expect(
        recordPrecedesBirth(
          recordMs: day(2026, 5, 1),
          birthMs: day(2026, 5, 1),
        ),
        isFalse,
        reason:
            'a puppy weighed on the day it was born is a fact, and the '
            'weigh-in has to be recordable',
      );
    });

    test('the day after the birth is legal', () {
      expect(
        recordPrecedesBirth(
          recordMs: day(2026, 5, 2),
          birthMs: day(2026, 5, 1),
        ),
        isFalse,
      );
    });

    test('an animal with no birth date refuses nothing', () {
      expect(
        recordPrecedesBirth(recordMs: day(2011, 1, 1), birthMs: null),
        isFalse,
        reason:
            'the birth date is the breeder\'s not-yet-known fact, and a record '
            'cannot be refused against an absence',
      );
    });

    test('a record with no date refuses nothing', () {
      expect(
        recordPrecedesBirth(recordMs: null, birthMs: day(2026, 5, 1)),
        isFalse,
      );
    });

    test('a late hour on the birth day does not make a record earlier', () {
      expect(
        recordPrecedesBirth(
          recordMs: day(2026, 5, 1, hour: 23),
          birthMs: day(2026, 5, 1, hour: 1),
        ),
        isFalse,
        reason:
            'the same D31/D32 rule as the litter pair: a day is a date, not '
            '86,400,000 ms, so a record made late in the evening of the day an '
            'animal was born is on the day it was born',
      );
    });

    test('a year boundary is a day before, not an hour difference', () {
      expect(
        recordPrecedesBirth(
          recordMs: day(2025, 12, 31, hour: 23),
          birthMs: day(2026, 1, 1, hour: 1),
        ),
        isTrue,
      );
    });
  });
}
