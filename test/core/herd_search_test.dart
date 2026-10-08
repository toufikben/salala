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
  String? notes,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: AnimalStatus.active,
  breed: breed,
  registrationNo: registrationNo,
  microchipId: microchipId,
  notes: notes,
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

    test('the rounded square and the two neighbours of a plain yeh fold too', () {
      // Code points rather than literals, because `ى`, `ی` and `ي` are three
      // shapes this test has to tell apart and a source file cannot show which
      // one was actually typed. CI found the difference the hard way: the second
      // of these is what a Persian-layout keyboard writes, and it was passing
      // through unfolded, so a query in that shape missed the animal the ledger
      // already had.
      expect(normalizeForSearch('حم\u0629'), 'حم\u0647');
      expect(normalizeForSearch('بن\u0649'), 'بن\u064A');
      expect(normalizeForSearch('بن\u06CC'), 'بن\u064A');
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

    test('the digits an Arabic numeral keyboard writes find a Latin number', () {
      // D21 is a rule about what this app paints, not about which keys the
      // phone next to it offers. A breeder reading a certificate aloud types the
      // shape they see, and before this fold `٢٥٠` matched nothing in a ledger
      // that held `ATL-2500` — the same no-answer a missing dog looks like.
      expect(normalizeForSearch('٢٥٠'), '250');
      expect(normalizeForSearch('۰۱۲'), '012'); // Persian extended forms
      final herd = <Animal>[
        _animal('a-1', 'Zida'),
        _animal('a-2', 'Nala', registrationNo: 'ATL-2500'),
      ];

      expect(searchHerd(herd, '٢٥٠').single.id, 'a-2');
    });

    test('the French ligature is two letters, not an unknown one', () {
      expect(normalizeForSearch('cœur'), 'coeur');
    });

    test('normalising twice changes nothing after the first pass', () {
      final once = normalizeForSearch('سُلَيْطَة 984-A');
      expect(normalizeForSearch(once), once);
    });
  });

  group('what counts as a query at all', () {
    test('text that normalises to nothing asks for nothing', () {
      // A keyboard that auto-inserts a space, or a dash typed ahead of a number
      // nobody stored with one: the list does not change, so the screen must not
      // behave as if it had.
      expect(queryFilters(''), isFalse);
      expect(queryFilters('   '), isFalse);
      expect(queryFilters(' — '), isFalse);
      expect(queryFilters('a'), isTrue);
      expect(queryFilters('ش'), isTrue);
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

    test('the animal remembered by what was written about it is found', () {
      final herd = <Animal>[
        _animal('a-1', 'Zida'),
        _animal('a-2', 'Nala', notes: 'limping on the left fore'),
      ];

      expect(searchHerd(herd, 'limping').single.id, 'a-2');
    });

    test('a note answers, but below the field that is about the animal', () {
      final herd = <Animal>[
        _animal('a-1', 'Zida', notes: 'Referred for a rabies booster'),
        _animal('a-2', 'Nala', registrationNo: 'RAB-2024'),
      ];

      expect(searchHerd(herd, 'rab').map((Animal a) => a.id), <String>[
        'a-2',
        'a-1',
      ]);
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
      'a name that merely contains the query still beats the number typed in '
      'full',
      () {
        // The ladder in `herd_search.dart` says any name hit outranks any
        // number hit. It only says that if the rungs are a whole step apart:
        // when a name substring and an exact registration both scored 3, the
        // dog whose number was typed in full lost to whichever row the database
        // happened to return first.
        final herd = <Animal>[
          _animal('a-1', 'Sirin', registrationNo: 'Zid'),
          _animal('a-2', 'Azida'),
        ];

        expect(searchHerd(herd, 'zid').first.id, 'a-2');
      },
    );

    test(
      'the exact chip is not hidden behind the registration that only contains '
      'the digits',
      () {
        // Both numbers belong to the same animal, so the loop that reads them
        // has to keep the best answer rather than take the first one that
        // answered at all.
        final herd = <Animal>[
          _animal('a-1', 'Zida', registrationNo: 'MA-1180'),
          _animal('a-2', 'Nala', registrationNo: 'MA-118', microchipId: '118'),
        ];

        expect(searchHerd(herd, '118').map((Animal a) => a.id), <String>[
          'a-2',
          'a-1',
        ]);
      },
    );

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
