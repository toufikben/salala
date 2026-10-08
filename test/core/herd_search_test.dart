import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/herd_search.dart';
import 'package:salala/data/models/animal.dart';

/// What a query matches, and in what order it comes back.
///
/// No page is involved here on purpose. A search box is a `TextField` and a
/// filter, and the part that can be wrong without anyone seeing it is the
/// normalisation: a query that fails because of a hamza the keyboard chose looks
/// exactly like a herd that does not contain the animal.
Animal _animal(
  String id,
  String name, {
  String? breed,
  String? registrationNo,
  String? microchipId,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  breed: breed,
  registrationNo: registrationNo,
  microchipId: microchipId,
  createdAt: 1740000000000,
  updatedAt: 1740000000000,
);

void main() {
  group('normalisation', () {
    test(
      'the hamza shapes a keyboard offers are the alef the ledger holds',
      () {
        expect(normalizeForSearch('أسود'), normalizeForSearch('اسود'));
        expect(normalizeForSearch('إبل'), normalizeForSearch('ابل'));
        expect(normalizeForSearch('مؤدّس'), normalizeForSearch('مودس'));
      },
    );

    test('the rounded square and the alef-maqsura fold too', () {
      expect(normalizeForSearch('حمزة'), normalizeForSearch('حمزه'));
      expect(normalizeForSearch('بنى'), normalizeForSearch('بنی'));
    });

    test('a name typed with vowel marks matches the name without them', () {
      expect(normalizeForSearch('شَهد'), 'شهد');
    });

    test('accents are folded, not deleted', () {
      // Deleting them would turn "Zoé" into "zo", so the search that typed the
      // unaccented form of a name the ledger already has would find nothing.
      expect(normalizeForSearch('Zoé'), 'zoe');
      expect(normalizeForSearch('Zoë'), 'zoe');
      expect(normalizeForSearch('Müller'), 'muller');
    });

    test('spaces and dashes go, because a sticker is not a keyboard', () {
      expect(normalizeForSearch('984 221-330 / A'), '984221330a');
    });

    test('normalising twice changes nothing after the first pass', () {
      final once = normalizeForSearch('سُلَيْطَة 984-A');
      expect(normalizeForSearch(once), once);
    });
  });

  group('what a query matches', () {
    test('an empty query returns the herd untouched', () {
      final herd = <Animal>[_animal('a-1', 'Zida'), _animal('a-2', 'Atlas')];

      expect(searchHerd(herd, '   '), herd);
      expect(searchHerd(herd, ''), herd);
    });

    test('a name is found whatever the keyboard did to its letters', () {
      final herd = <Animal>[_animal('a-1', 'أسود'), _animal('a-2', 'Zida')];

      expect(searchHerd(herd, 'اسود').single.id, 'a-1');
      // Typed the other way round as well: the ledger can hold either shape.
      expect(
        searchHerd(<Animal>[_animal('a-1', 'اسود')], 'أسود').single.id,
        'a-1',
      );
    });

    test(
      'a microchip read off a sticker with spaces in it still finds the dog',
      () {
        final herd = <Animal>[
          _animal('a-1', 'Zida', microchipId: '984221330'),
          _animal('a-2', 'Nala'),
        ];

        expect(searchHerd(herd, '984 221 330').single.id, 'a-1');
        expect(searchHerd(herd, '9842').single.id, 'a-1');
      },
    );

    test('a registration number is an answer, and a breed is a weaker one', () {
      final herd = <Animal>[
        _animal('a-1', 'Zida', breed: 'سلوقي'),
        _animal('a-2', 'Nala', registrationNo: 'MA-2024-118'),
      ];

      expect(searchHerd(herd, 'MA-2024-118').single.id, 'a-2');
      expect(searchHerd(herd, 'سلوقي').single.id, 'a-1');
    });

    test('a query nothing answers comes back empty', () {
      final herd = <Animal>[_animal('a-1', 'Zida')];
      expect(searchHerd(herd, 'zzz'), isEmpty);
    });
  });

  group('the order matches come back in', () {
    test(
      'a whole name beats a prefix, and a prefix beats a middle of a name',
      () {
        final herd = <Animal>[
          _animal('a-1', 'Zidan'),
          _animal('a-2', 'Nazida'),
          _animal('a-3', 'Zida'),
        ];

        expect(searchHerd(herd, 'zida').map((Animal a) => a.id), <String>[
          'a-3',
          'a-1',
          'a-2',
        ]);
      },
    );

    test('a name hit outranks a number hit of the same length', () {
      final herd = <Animal>[
        _animal('a-1', 'Nine', microchipId: 'Nine-9'),
        _animal('a-2', 'Sirin', registrationNo: 'XnineX'),
      ];

      expect(searchHerd(herd, 'nine').first.id, 'a-1');
    });

    test(
      'the exact number comes before the number that merely contains it',
      () {
        final herd = <Animal>[
          _animal('a-1', 'Zida', registrationNo: 'MA-118'),
          _animal('a-2', 'Nala', registrationNo: '118'),
        ];

        expect(searchHerd(herd, '118').map((Animal a) => a.id), <String>[
          'a-2',
          'a-1',
        ]);
      },
    );

    test('two equally good matches keep the order the list was already in', () {
      // `List.sort` is not stable, and a list that rearranges two cards on every
      // keystroke looks broken even when the set is right.
      final herd = <Animal>[
        _animal('a-1', 'Zaid'),
        _animal('a-2', 'Zayn'),
        _animal('a-3', 'Zaida'),
      ];

      expect(searchHerd(herd, 'zai').map((Animal a) => a.id), <String>[
        'a-1',
        'a-3',
      ]);
      for (var i = 0; i < 20; i++) {
        expect(
          searchHerd(herd.reversed.toList(), 'zai').map((Animal a) => a.id),
          <String>['a-3', 'a-1'],
        );
      }
    });

    test('a chip typed from memory shows every animal it could be', () {
      final herd = <Animal>[
        _animal('a-1', 'Zida', microchipId: '984'),
        _animal('a-2', 'Nala', microchipId: '9842'),
        _animal('a-3', 'Sirin', breed: 'dog'),
      ];

      // The partial number is not a wrong answer, so it stays in the list; the
      // one typed in full is the one that goes on top.
      expect(searchHerd(herd, '984').map((Animal a) => a.id), <String>[
        'a-1',
        'a-2',
      ]);
    });
  });
}
