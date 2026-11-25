import 'package:flutter_test/flutter_test.dart';
import 'package:companion/services/pack_files.dart';

void main() {
  final at = DateTime(2026, 10, 5, 20, 41);

  group('fileStamp', () {
    test('pads to two digits so a day of exports sort in order', () {
      expect(fileStamp(DateTime(2026, 1, 2, 3, 4)), '20260102-0304');
    });

    test('is four digits of minute, so two exports on one day differ', () {
      expect(fileStamp(at), '20261005-2041');
    });
  });

  test('packFileName carries the stamp, no animal, and the container', () {
    // `.zip`, because the file holds the pictures as well as the rows now.
    expect(packFileName(at), 'companion-pack-20261005-2041.zip');
  });

  group('pdfFileName', () {
    test(
      'slug is the animal, because it is what lands in a buyer\'s phone',
      () {
        expect(pdfFileName('Nala', at), 'companion-nala-20261005-2041.pdf');
      },
    );

    test('spaces and punctuation become one dash, and case goes', () {
      expect(
        pdfFileName('  Zida of Atlas  ', at),
        'companion-zida-of-atlas-20261005-2041.pdf',
      );
      expect(
        pdfFileName("Nala's Pup, L1", at),
        'companion-nala-s-pup-l1-20261005-2041.pdf',
      );
    });

    test(
      'a wholly non-Latin name slugs away to nothing and the stamp carries it',
      () {
        // The file still has to arrive with a usable name, so it must not be
        // `companion-.pdf` either.
        expect(pdfFileName('نالة', at), 'companion-20261005-2041.pdf');
      },
    );

    test('digits and letters that survive are kept, so two litters differ', () {
      expect(pdfFileName('L1 2026', at), 'companion-l1-2026-20261005-2041.pdf');
    });
  });
}
