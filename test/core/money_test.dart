import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/money.dart';

/// Money in and money out, with no locale and no symbol anywhere in between.
///
/// These two functions are the whole of this app's money handling, and the PDF
/// now prints a price through them. A `2500.00` on a family's copy of a sale is
/// the kind of thing that turns into an argument, so the shape of the string is
/// worth pinning down rather than leaving to how the field happens to render.
void main() {
  group('parsePrice', () {
    test('a whole amount typed without a decimal point is stored as one', () {
      expect(parsePrice('2500'), 2500.0);
    });

    test('a comma is the decimal separator the keyboards here print', () {
      expect(parsePrice('250,50'), 250.5);
      expect(parsePrice('250.50'), 250.5);
    });

    test("spaces around the amount are the field's, not part of the price", () {
      expect(parsePrice('  9000 '), 9000.0);
    });

    test('nothing typed is nothing recorded, not a zero', () {
      expect(parsePrice(''), isNull);
      expect(parsePrice('   '), isNull);
    });

    test('a zero is a gift, and a negative is not a price', () {
      expect(parsePrice('0'), isNull);
      expect(parsePrice('-2500'), isNull);
    });

    test('letters and an empty number are refused, not coerced', () {
      expect(parsePrice('2500 MAD'), isNull);
      expect(parsePrice('abc'), isNull);
      expect(parsePrice('.'), isNull);
      expect(parsePrice('MAD'), isNull);
    });
  });

  group('formatPrice', () {
    test(
      'a whole price loses its cents instead of reading like a measurement',
      () {
        expect(formatPrice(2500), '2500');
        expect(formatPrice(9000.0), '9000');
      },
    );

    test('the digits a price actually has are kept', () {
      expect(formatPrice(250.25), '250.25');
      expect(formatPrice(0.75), '0.75');
    });

    test('a trailing zero in the cents is shaved off, not padded', () {
      expect(formatPrice(250.5), '250.5');
      expect(formatPrice(1.0), '1');
    });

    test('the Latin digits survive (D21)', () {
      final text = formatPrice(2500);
      expect(text, matches(RegExp(r'^[0-9.]+$')));
    });

    test('a stored float is read back to two decimals, not to its noise', () {
      expect(formatPrice(0.1 + 0.2), '0.3');
    });

    test('the amount a breeder typed is the amount a document prints', () {
      expect(formatPrice(parsePrice('2500')!), '2500');
      expect(formatPrice(parsePrice('250,50')!), '250.5');
    });
  });

  group('formatPriceWithCurrency', () {
    test('the code goes beside the amount, in Latin digits', () {
      expect(
        formatPriceWithCurrency(2500, 'MAD', unknown: 'Not recorded'),
        '2500 MAD',
      );
      expect(
        formatPriceWithCurrency(250.5, 'MAD', unknown: 'Not recorded'),
        '250.5 MAD',
      );
    });

    test('a price with no currency is not a trailing space', () {
      expect(
        formatPriceWithCurrency(2500, null, unknown: 'Not recorded'),
        '2500',
      );
      expect(
        formatPriceWithCurrency(2500, '', unknown: 'Not recorded'),
        '2500',
      );
    });

    test('nothing written down is the words for that, never zero', () {
      expect(
        formatPriceWithCurrency(null, 'MAD', unknown: 'Not recorded'),
        'Not recorded',
      );
      // The test's name promised this and the code only held half of it. A zero
      // cannot be typed (`parsePrice` refuses it) but it can come back in a
      // restored pack, and a page that reads `Price 0 MAD` says the dog was
      // free.
      expect(
        formatPriceWithCurrency(0, 'MAD', unknown: 'Not recorded'),
        'Not recorded',
      );
      expect(
        formatPriceWithCurrency(-2500, 'MAD', unknown: 'Not recorded'),
        'Not recorded',
      );
    });
  });
}
