import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/utils/litter_rows.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';

/// What the whelping record says, before any page is drawn.
///
/// The bytes of a PDF cannot be read back in a test — the letters go through the
/// embedded font's glyph ids — so the words are pinned here, at the layer that
/// chooses them. What is left for the phone is whether the page they end up on
/// reads correctly.
Future<AppLocalizations> messages(String language) =>
    AppLocalizations.delegate.load(Locale(language));

Animal _puppy(
  String id,
  String name, {
  Sex sex = Sex.female,
  AnimalStatus status = AnimalStatus.active,
  int? birthDate,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: sex,
  status: status,
  birthDate: birthDate,
  createdAt: 1740000000000,
  updatedAt: 1740000000000,
);

LitterPuppy _litterPuppy(
  Animal animal, {
  List<Vaccination> doses = const <Vaccination>[],
  List<WeightEntry> weighIns = const <WeightEntry>[],
  List<Placement> placements = const <Placement>[],
}) => LitterPuppy(
  animal: animal,
  doses: doses,
  weighIns: weighIns,
  placements: placements,
);

Vaccination _dose(
  String animalId,
  String name,
  int given, {
  int? due,
  String? vet,
}) => Vaccination(
  id: 'v-$animalId-$name',
  animalId: animalId,
  vaccineName: name,
  dateAdministered: given,
  nextDueDate: due,
  vetName: vet,
  createdAt: given,
  updatedAt: given,
);

WeightEntry _weighIn(String animalId, int grams, int at) => WeightEntry(
  id: 'w-$animalId-$at',
  animalId: animalId,
  weightGrams: grams,
  measuredAt: at,
);

Placement _placement(
  String animalId,
  String? buyerId, {
  int? placedDate,
  double? price,
  String? currency,
}) => Placement(
  id: 'p-$animalId',
  animalId: animalId,
  buyerId: buyerId,
  placedDate: placedDate,
  price: price,
  currency: currency,
  createdAt: 1750000000000,
  updatedAt: 1750000000000,
);

final _day = DateTime(2025, 10, 18).millisecondsSinceEpoch;
final _laterDay = DateTime(2025, 11, 2).millisecondsSinceEpoch;
final _arabicIndicDigits = RegExp(r'[٠-٩]');

void main() {
  setUpAll(initializeDateFormatting);

  test(
    'the whelping facts are the parents and the three dates, in order',
    () async {
      final l10n = await messages('en');

      final facts = whelpingFacts(
        l10n,
        'en',
        damName: 'Zida',
        sireName: 'Atlas',
        matingDate: _day,
        whelpingDate: _laterDay,
        weaningDate: null,
      );

      expect(facts[0].$1, l10n.litterDam);
      expect(facts[0].$2, 'Zida');
      expect(facts[1].$1, l10n.litterSire);
      expect(facts[1].$2, 'Atlas');
      expect(facts[2].$1, l10n.litterMatingDate);
      expect(facts[2].$2, contains('2025'));
      expect(facts[3].$1, l10n.litterWhelpingDate);
      expect(facts[3].$2, contains('2025'));
      expect(facts[4].$1, l10n.litterWeaningDate);
      expect(facts[4].$2, l10n.valueUnknown);
    },
  );

  test(
    'a sire and a date nobody wrote down are named as missing, not left blank',
    () async {
      final l10n = await messages('en');

      final facts = whelpingFacts(
        l10n,
        'en',
        damName: 'Zida',
        sireName: null,
        matingDate: null,
        whelpingDate: null,
        weaningDate: null,
      );

      expect(facts[1].$2, l10n.litterSireUnknown);
      // A blank cell on paper reads as a whelping that never happened, so every
      // gap gets the app's own words.
      for (final fact in facts.skip(2)) {
        expect(fact.$2, l10n.valueUnknown);
      }
    },
  );

  test('a puppy row carries the newest weigh-in only', () async {
    final l10n = await messages('en');

    final rows = puppyRows(l10n, 'en', <LitterPuppy>[
      _litterPuppy(
        _puppy('a-1', 'Sirin', birthDate: _laterDay),
        weighIns: <WeightEntry>[
          _weighIn('a-1', 900, _day),
          _weighIn('a-1', 2400, _laterDay),
        ],
      ),
    ]);

    expect(rows.single, <Object>[
      'Sirin',
      l10n.sexFemale,
      contains('2025'),
      l10n.statusActive,
      '2.40 ${l10n.unitKg}',
    ]);
  });

  test(
    'a puppy with no weigh-in and no birth date says so in its row',
    () async {
      final l10n = await messages('en');

      final rows = puppyRows(l10n, 'en', <LitterPuppy>[
        _litterPuppy(_puppy('a-1', 'Sirin', sex: Sex.male)),
      ]);

      expect(rows.single[1], l10n.sexMale);
      expect(rows.single[2], l10n.valueUnknown);
      expect(rows.single[4], l10n.valueUnknown);
    },
  );

  test('every dose is its own row, with the puppy named first', () async {
    final l10n = await messages('en');

    final rows = doseRows(l10n, 'en', <LitterPuppy>[
      _litterPuppy(
        _puppy('a-1', 'Sirin'),
        doses: <Vaccination>[
          _dose('a-1', 'Rabies', _laterDay, due: _day, vet: 'Dr Hakam'),
        ],
      ),
      _litterPuppy(
        _puppy('a-2', 'Zuzu'),
        doses: <Vaccination>[_dose('a-2', 'DHPP', _day)],
      ),
    ]);

    expect(rows.length, 2);
    expect(rows[0], <Object>[
      'Sirin',
      'Rabies',
      contains('2025'),
      contains('2025'),
      'Dr Hakam',
    ]);
    // The next-due date the breeder never typed is printed as a gap, the same
    // way the animal's own pack prints it: a blank cell in a dose column reads as
    // "no booster needed".
    expect(rows[1], <Object>[
      'Zuzu',
      'DHPP',
      contains('2025'),
      l10n.valueUnknown,
      l10n.valueUnknown,
    ]);
  });

  test('the puppy that was skipped is the one missing from the dose rows', () async {
    // The whole reason this table exists: a round given to a litter of three is
    // two rows here, and the breeder reads the absent name as the missed shot.
    final l10n = await messages('en');

    final rows = doseRows(l10n, 'en', <LitterPuppy>[
      _litterPuppy(
        _puppy('a-1', 'Sirin'),
        doses: <Vaccination>[_dose('a-1', 'DHPP', _day)],
      ),
      _litterPuppy(_puppy('a-2', 'Zuzu')),
      _litterPuppy(
        _puppy('a-3', 'Nala'),
        doses: <Vaccination>[_dose('a-3', 'DHPP', _day)],
      ),
    ]);

    expect(rows.map((List<String> row) => row.first), <String>[
      'Sirin',
      'Nala',
    ]);
  });

  test(
    'a handover prints the buyer, the day, and money with its code',
    () async {
      final l10n = await messages('en');
      final buyers = <Buyer>[
        Buyer(
          id: 'b-1',
          name: 'Nadia Sabri',
          createdAt: 1750000000000,
          updatedAt: 1750000000000,
        ),
      ];

      final rows = handoverRows(l10n, 'en', <LitterPuppy>[
        _litterPuppy(
          _puppy('a-1', 'Sirin', status: AnimalStatus.sold),
          placements: <Placement>[
            _placement(
              'a-1',
              'b-1',
              placedDate: _day,
              price: 2500,
              currency: 'MAD',
            ),
          ],
        ),
        _litterPuppy(
          _puppy('a-2', 'Zuzu', status: AnimalStatus.sold),
          placements: <Placement>[_placement('a-2', null, price: 250.5)],
        ),
      ], buyers);

      expect(rows[0], <Object>[
        'Sirin',
        'Nadia Sabri',
        contains('2025'),
        '2500 MAD',
      ]);
      // No buyer and no day: the handover still belongs on the page, with both
      // gaps named out loud, and a price with no currency is not a trailing space.
      expect(rows[1], <Object>[
        'Zuzu',
        l10n.placementNoBuyer,
        l10n.valueUnknown,
        '250.5',
      ]);
    },
  );

  test('a handover whose buyer was deleted is still a handover', () async {
    final l10n = await messages('en');

    final rows = handoverRows(l10n, 'en', <LitterPuppy>[
      _litterPuppy(
        _puppy('a-1', 'Sirin'),
        placements: <Placement>[_placement('a-1', 'b-gone')],
      ),
    ], const <Buyer>[]);

    expect(rows.single[1], l10n.placementNoBuyer);
  });

  test('an empty litter makes three empty tables, not an error', () async {
    final l10n = await messages('en');

    expect(puppyRows(l10n, 'en', const <LitterPuppy>[]), isEmpty);
    expect(doseRows(l10n, 'en', const <LitterPuppy>[]), isEmpty);
    expect(
      handoverRows(l10n, 'en', const <LitterPuppy>[], const <Buyer>[]),
      isEmpty,
    );
  });

  test('Arabic rows keep Latin digits and Arabic words', () async {
    final l10n = await messages('ar');

    final rows = puppyRows(l10n, 'ar', <LitterPuppy>[
      _litterPuppy(
        _puppy('a-1', 'نالة', birthDate: _day),
        weighIns: <WeightEntry>[_weighIn('a-1', 430, _day)],
      ),
    ]);

    expect(rows.single[1], l10n.sexFemale);
    // A gram-weight stays grams: nobody holds a 430 g puppy in kilograms.
    expect(rows.single[4], '430 ${l10n.unitGrams}');
    expect(
      _arabicIndicDigits.hasMatch(rows.single[2]),
      isFalse,
      reason:
          'D21: the date and the weight on one row are one numeral system, and a '
          'breeder checks either against a certificate typed in Latin digits',
    );
  });
}
