import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/utils/animal_rows.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/symptom.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/data/models/weight_entry.dart';

/// What the buyer's document says, before any page is drawn.
///
/// The four wording defects of Stage 3e — the handover that vanished, the price
/// without its currency, the country nobody printed, the weight column under the
/// wrong heading — were all found by a human holding a page, because the words
/// were written inside the layout. This file is the layer where CI can read them
/// back (D29).
Future<AppLocalizations> messages(String language) =>
    AppLocalizations.delegate.load(Locale(language));

Animal _animal(
  String id,
  String name, {
  Sex sex = Sex.female,
  AnimalStatus status = AnimalStatus.active,
  int? birthDate,
  int? deathDate,
  String? breed,
  String? registrationNo,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: sex,
  status: status,
  breed: breed,
  birthDate: birthDate,
  deathDate: deathDate,
  registrationNo: registrationNo,
  createdAt: 1700000000000,
  updatedAt: 1700000000000,
);

final _day = DateTime(2025, 10, 18).millisecondsSinceEpoch;
final _laterDay = DateTime(2025, 11, 2).millisecondsSinceEpoch;
final _arabicIndicDigits = RegExp(r'[٠-٩]');

void main() {
  setUpAll(initializeDateFormatting);

  group('animalFacts', () {
    test(
      'a complete animal prints every identity line, in the ledger order',
      () async {
        final l10n = await messages('en');

        final facts = animalFacts(
          l10n,
          'en',
          _animal(
            'a-1',
            'Zida',
            birthDate: _day,
            breed: 'Canary',
            registrationNo: 'LOE-1188',
          ),
        );

        expect(facts.map(((String, String) fact) => fact.$1).toList(), <String>[
          l10n.animalSpecies,
          l10n.animalBreed,
          l10n.animalSex,
          l10n.animalStatus,
          l10n.animalBirthDate,
          l10n.animalColor,
          l10n.animalRegistrationNo,
          l10n.animalRegistry,
          l10n.animalMicrochip,
        ]);
        expect(facts[0].$2, 'dog');
        expect(facts[1].$2, 'Canary');
        expect(facts[2].$2, l10n.sexFemale);
        expect(facts[3].$2, l10n.statusActive);
        expect(facts[6].$2, 'LOE-1188');
      },
    );

    test('a field nobody typed is named as unknown, not left blank', () async {
      final l10n = await messages('en');

      final facts = animalFacts(l10n, 'en', _animal('a-1', 'Zida'));

      // On paper an empty cell reads as "the breeder would not say", which is a
      // claim about the animal; "Unknown" is a claim about the record.
      expect(facts[1].$2, l10n.valueUnknown);
      expect(facts[4].$2, l10n.valueUnknown);
      expect(facts[6].$2, l10n.valueUnknown);
      expect(facts[8].$2, l10n.valueUnknown);
    });

    test(
      'a living animal has no death line, and a dead one has it in place',
      () async {
        final l10n = await messages('en');

        final living = animalFacts(l10n, 'en', _animal('a-1', 'Zida'));
        expect(
          living.any(
            ((String, String) fact) => fact.$1 == l10n.animalDeathDate,
          ),
          isFalse,
          reason:
              'a document that says a live animal died is the worst line it could '
              'carry',
        );

        final dead = animalFacts(
          l10n,
          'en',
          _animal(
            'a-2',
            'Atlas',
            sex: Sex.male,
            status: AnimalStatus.deceased,
            deathDate: _laterDay,
          ),
        );
        expect(dead[5].$1, l10n.animalDeathDate);
        expect(dead[5].$2, contains('2025'));
        expect(dead.map(((String, String) fact) => fact.$1).length, 10);
      },
    );
  });

  group('the record tables', () {
    test('a dose prints its own vet, and an unwritten one says so', () async {
      final l10n = await messages('en');

      final rows = vaccinationRows(l10n, 'en', <Vaccination>[
        Vaccination(
          id: 'v-1',
          animalId: 'a-1',
          vaccineName: 'Rabies',
          dateAdministered: _day,
          vetName: 'Dr Hakam',
          createdAt: _day,
          updatedAt: _day,
        ),
        Vaccination(
          id: 'v-2',
          animalId: 'a-1',
          vaccineName: 'DHPP',
          dateAdministered: _laterDay,
          createdAt: _laterDay,
          updatedAt: _laterDay,
        ),
      ]);

      expect(rows[0], <Object>[
        'Rabies',
        contains('2025'),
        l10n.valueUnknown,
        'Dr Hakam',
      ]);
      expect(rows[1][3], l10n.valueUnknown);
      // A dose with no next-due date is printed as a gap rather than a blank,
      // because a blank in that column reads as "no booster needed".
      expect(rows[0][2], l10n.valueUnknown);
    });

    test(
      'a screening prints what was tested, the result and its expiry',
      () async {
        final l10n = await messages('en');

        final rows = screeningRows(l10n, 'en', <HealthTest>[
          HealthTest(
            id: 'h-1',
            animalId: 'a-1',
            testType: 'HD',
            result: '0/0',
            testDate: _day,
            createdAt: _day,
            updatedAt: _day,
          ),
        ]);

        expect(rows.single, <Object>[
          'HD',
          '0/0',
          contains('2025'),
          l10n.valueUnknown,
        ]);
      },
    );

    test(
      'a weigh-in is a day and a weight, in the unit the weight deserves',
      () async {
        final l10n = await messages('en');

        final rows = weighInRows(l10n, 'en', <WeightEntry>[
          WeightEntry(
            id: 'w-1',
            animalId: 'a-1',
            weightGrams: 430,
            measuredAt: _day,
          ),
          WeightEntry(
            id: 'w-2',
            animalId: 'a-1',
            weightGrams: 12400,
            measuredAt: _laterDay,
          ),
        ]);

        expect(rows[0][0], contains('2025'));
        // Nobody holds a 430 g puppy in kilograms, and a buyer reading "0.43 kg" off
        // a certificate in grams thinks the record is wrong.
        expect(rows[0][1], '430 ${l10n.unitGrams}');
        expect(rows[1][1], '12.40 ${l10n.unitKg}');
      },
    );

    test('a visit with no reason written is still a visit', () async {
      final l10n = await messages('en');

      final rows = visitRows(l10n, 'en', <VetVisit>[
        VetVisit(
          id: 't-1',
          animalId: 'a-1',
          visitDate: _day,
          createdAt: _day,
          updatedAt: _day,
        ),
        VetVisit(
          id: 't-2',
          animalId: 'a-1',
          visitDate: _laterDay,
          reason: 'Limping after a fall',
          outcome: 'Rest, no fracture',
          createdAt: _laterDay,
          updatedAt: _laterDay,
        ),
      ]);

      expect(rows[0], <Object>[
        contains('2025'),
        l10n.visitNoReason,
        l10n.valueUnknown,
      ]);
      expect(rows[1][1], 'Limping after a fall');
      expect(rows[1][2], 'Rest, no fracture');
    });

    test(
      'a symptom prints its severity and whether it is still there',
      () async {
        final l10n = await messages('en');

        final rows = symptomRows(l10n, 'en', <Symptom>[
          Symptom(
            id: 's-1',
            animalId: 'a-1',
            label: 'Soft stool',
            severity: SymptomSeverity.moderate,
            observedAt: _day,
            ongoing: true,
            createdAt: _day,
            updatedAt: _day,
          ),
          Symptom(
            id: 's-2',
            animalId: 'a-1',
            label: 'Scratching',
            severity: SymptomSeverity.mild,
            observedAt: _laterDay,
            ongoing: false,
            note: 'Stopped after the shampoo',
            createdAt: _laterDay,
            updatedAt: _laterDay,
          ),
        ]);

        expect(rows[0], <Object>[
          'Soft stool',
          contains('2025'),
          l10n.severityModerate,
          l10n.symptomOngoing,
          l10n.valueUnknown,
        ]);
        expect(rows[0][3], isNot(rows[1][3]));
        expect(rows[1][3], l10n.symptomResolved);
        expect(rows[1][4], 'Stopped after the shampoo');
      },
    );

    test('a breeding row says which side of the pedigree this animal stood on', () async {
      final l10n = await messages('en');
      final litter = Litter(
        id: 'l-1',
        name: 'L1 2025',
        damId: 'a-dam',
        sireId: 'a-sire',
        whelpingDate: _day,
        createdAt: _day,
        updatedAt: _day,
      );

      final asDam = breedingRows(l10n, 'en', 'a-dam', <LitterOutcome>[
        LitterOutcome(litter: litter, puppies: 6),
      ]);
      final asSire = breedingRows(l10n, 'en', 'a-sire', <LitterOutcome>[
        LitterOutcome(litter: litter, puppies: 6),
      ]);
      final noDate = breedingRows(l10n, 'en', 'a-dam', <LitterOutcome>[
        LitterOutcome(
          litter: Litter(
            id: 'l-2',
            name: 'L2',
            damId: 'a-dam',
            createdAt: _day,
            updatedAt: _day,
          ),
          puppies: 0,
        ),
      ]);

      expect(asDam.single, <Object>[
        'L1 2025',
        l10n.animalDam,
        contains('2025'),
        '6',
      ]);
      expect(asSire.single[1], l10n.animalSire);
      // A litter with no whelping date yet is a real one, and zero puppies is a
      // fact rather than a gap.
      expect(noDate.single, <Object>[
        'L2',
        l10n.animalDam,
        l10n.valueUnknown,
        '0',
      ]);
    });

    test(
      'an animal with no records makes five empty tables, not an error',
      () async {
        final l10n = await messages('en');

        expect(vaccinationRows(l10n, 'en', const <Vaccination>[]), isEmpty);
        expect(screeningRows(l10n, 'en', const <HealthTest>[]), isEmpty);
        expect(weighInRows(l10n, 'en', const <WeightEntry>[]), isEmpty);
        expect(visitRows(l10n, 'en', const <VetVisit>[]), isEmpty);
        expect(symptomRows(l10n, 'en', const <Symptom>[]), isEmpty);
        expect(
          breedingRows(l10n, 'en', 'a-1', const <LitterOutcome>[]),
          isEmpty,
        );
      },
    );
  });

  group('placementFacts', () {
    test(
      'a named buyer with a country prints the line a guarantee needs',
      () async {
        final l10n = await messages('en');
        final placement = Placement(
          id: 'p-1',
          animalId: 'a-1',
          buyerId: 'b-1',
          placedDate: _day,
          price: 2500,
          currency: 'MAD',
          guaranteeTerms: 'No breeding, health guaranteed for 18 months',
          createdAt: _day,
          updatedAt: _day,
        );
        final buyer = Buyer(
          id: 'b-1',
          name: 'Nadia Sabri',
          phone: '+212 6 12 34 56 78',
          email: 'nadia@example.ma',
          countryCode: 'MA',
          createdAt: _day,
          updatedAt: _day,
        );

        final facts = placementFacts(l10n, 'en', placement, buyer);

        expect(facts.map(((String, String) fact) => fact.$1).toList(), <String>[
          l10n.pdfBuyer,
          l10n.pdfPhone,
          l10n.pdfEmail,
          l10n.buyerCountryCode,
          l10n.pdfPlacedOn,
          l10n.pdfPrice,
          l10n.pdfGuarantee,
        ]);
        expect(facts[0].$2, 'Nadia Sabri');
        expect(facts[3].$2, 'MA');
        // The price carries its code: a bare number on a page that crosses a border
        // is a dispute waiting to happen.
        expect(facts[5].$2, '2500 MAD');
      },
    );

    test(
      'a deleted buyer and an unwritten price are gaps, not missing lines',
      () async {
        final l10n = await messages('en');
        final placement = Placement(
          id: 'p-1',
          animalId: 'a-1',
          buyerId: 'b-gone',
          createdAt: _day,
          updatedAt: _day,
        );

        final facts = placementFacts(l10n, 'en', placement, null);

        expect(facts[0].$2, l10n.valueUnknown);
        expect(facts[facts.length - 2].$1, l10n.pdfPlacedOn);
        expect(facts[facts.length - 2].$2, l10n.valueUnknown);
        expect(facts.last.$1, l10n.pdfPrice);
        expect(facts.last.$2, l10n.valueUnknown);
        // No contact details means no phone, email or country lines — an absent
        // address is not an address that happens to be empty.
        expect(facts.length, 3);
      },
    );

    test('a blank country code is not printed as a line', () async {
      final l10n = await messages('en');
      final placement = Placement(
        id: 'p-1',
        animalId: 'a-1',
        buyerId: 'b-1',
        price: 250.5,
        createdAt: _day,
        updatedAt: _day,
      );
      final buyer = Buyer(
        id: 'b-1',
        name: 'Nadia Sabri',
        countryCode: '',
        createdAt: _day,
        updatedAt: _day,
      );

      final facts = placementFacts(l10n, 'en', placement, buyer);

      expect(
        facts.any(((String, String) fact) => fact.$1 == l10n.buyerCountryCode),
        isFalse,
      );
      // A price with no currency is the amount alone — not a trailing space that
      // reads as a typo in the code.
      expect(facts.last.$2, '250.5');
    });

    test('an empty contact field gets no line, and a zero is not a price', () async {
      // Both arrive through a restored pack rather than the form: the form
      // refuses an empty phone and `parsePrice` refuses 0. A printed page has
      // to be right about the file it was given, though — a label over a blank
      // reads as a redaction, and `Price 0` tells the buyer the dog was free
      // when nobody recorded anything.
      final l10n = await messages('en');
      final placement = Placement(
        id: 'p-1',
        animalId: 'a-1',
        buyerId: 'b-1',
        price: 0,
        currency: 'MAD',
        createdAt: _day,
        updatedAt: _day,
      );
      final buyer = Buyer(
        id: 'b-1',
        name: 'Nadia Sabri',
        phone: '',
        email: '',
        createdAt: _day,
        updatedAt: _day,
      );

      final facts = placementFacts(l10n, 'en', placement, buyer);

      expect(facts.map(((String, String) fact) => fact.$1).toList(), <String>[
        l10n.pdfBuyer,
        l10n.pdfPlacedOn,
        l10n.pdfPrice,
      ]);
      expect(facts.last.$2, l10n.valueUnknown);
    });
  });

  test('the Arabic document keeps Latin digits and Arabic words', () async {
    final l10n = await messages('ar');

    final facts = animalFacts(
      l10n,
      'ar',
      _animal('a-1', 'نالة', birthDate: _day),
    );
    final rows = weighInRows(l10n, 'ar', <WeightEntry>[
      WeightEntry(
        id: 'w-1',
        animalId: 'a-1',
        weightGrams: 2400,
        measuredAt: _day,
      ),
    ]);

    expect(facts[2].$2, l10n.sexFemale);
    expect(facts[3].$2, l10n.statusActive);
    expect(rows.single[1], '2.40 ${l10n.unitKg}');
    for (final fact in facts) {
      expect(
        _arabicIndicDigits.hasMatch(fact.$2),
        isFalse,
        reason:
            'D21: one numeral system per page, because a buyer checks a date or a '
            'weight here against a certificate typed in Latin digits',
      );
    }
  });
}
