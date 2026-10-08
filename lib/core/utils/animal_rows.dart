/// The rows the buyer's document prints, worked out apart from the page.
///
/// The same split as `litter_rows.dart` (D29): a PDF draws its letters through
/// the embedded font's glyph ids, so a test over the bytes of a page cannot read
/// a single line back. Every stage-3e defect that CI missed — the dropped
/// handover, the missing country, the price without its currency — was a wording
/// bug living inside the layout, where only a human with a printed page could
/// find it. What is decided here is arithmetic, dates and labels; the service
/// that calls these only arranges them.
///
/// Nothing in this file touches the database. The caller reads first and hands
/// the rows over, because a document that queried from inside a table row would
/// be a query per cell.
library;

import '../../data/models/animal.dart';
import '../../data/models/buyer.dart';
import '../../data/models/health_test.dart';
import '../../data/models/litter.dart';
import '../../data/models/placement.dart';
import '../../data/models/symptom.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/vet_visit.dart';
import '../../data/models/weight_entry.dart';
import '../l10n/app_localizations.dart';
import '../l10n/enum_labels.dart';
import 'date_utils.dart';
import 'money.dart';
import 'weight.dart';

/// One litter this animal produced or sired, with how many puppies it had.
///
/// The count is read by the caller because it costs a query per litter; saying so
/// in the type is what keeps the row builder from quietly becoming the place a
/// document starts doing its own database work.
class LitterOutcome {
  const LitterOutcome({required this.litter, required this.puppies});

  final Litter litter;
  final int puppies;
}

/// What the animal is: species, breed, sex, status, dates and identifiers.
///
/// The death date is printed only when there is one. A live animal shown as dead
/// is the worst line this document could carry, and an empty one next to the
/// heading "Date of death" reads like it was hidden rather than absent.
List<(String, String)> animalFacts(
  AppLocalizations l10n,
  String localeTag,
  Animal animal,
) => <(String, String)>[
  (l10n.animalSpecies, animal.species),
  (l10n.animalBreed, animal.breed ?? l10n.valueUnknown),
  (l10n.animalSex, sexLabel(l10n, animal.sex)),
  (l10n.animalStatus, statusLabel(l10n, animal.status)),
  (l10n.animalBirthDate, formatDayOrUnknown(l10n, localeTag, animal.birthDate)),
  if (animal.deathDate != null)
    (
      l10n.animalDeathDate,
      formatDayOrUnknown(l10n, localeTag, animal.deathDate),
    ),
  (l10n.animalColor, animal.color ?? l10n.valueUnknown),
  (l10n.animalRegistrationNo, animal.registrationNo ?? l10n.valueUnknown),
  (l10n.animalRegistry, animal.registry ?? l10n.valueUnknown),
  (l10n.animalMicrochip, animal.microchipId ?? l10n.valueUnknown),
];

/// This animal's own doses, one row each.
///
/// Not the litter document's `doseRows`, which has to name the puppy first
/// because a whole litter shares one table. Here every row is the same animal, so
/// the name would be printed once per line for nothing.
List<List<String>> vaccinationRows(
  AppLocalizations l10n,
  String localeTag,
  List<Vaccination> doses,
) => <List<String>>[
  for (final Vaccination dose in doses)
    <String>[
      dose.vaccineName,
      formatDayOrUnknown(l10n, localeTag, dose.dateAdministered),
      formatDayOrUnknown(l10n, localeTag, dose.nextDueDate),
      dose.vetName ?? l10n.valueUnknown,
    ],
];

List<List<String>> screeningRows(
  AppLocalizations l10n,
  String localeTag,
  List<HealthTest> tests,
) => <List<String>>[
  for (final HealthTest test in tests)
    <String>[
      test.testType,
      test.result,
      formatDayOrUnknown(l10n, localeTag, test.testDate),
      formatDayOrUnknown(l10n, localeTag, test.validUntil),
    ],
];

List<List<String>> weighInRows(
  AppLocalizations l10n,
  String localeTag,
  List<WeightEntry> weighIns,
) => <List<String>>[
  for (final WeightEntry entry in weighIns)
    <String>[
      formatDayOrUnknown(l10n, localeTag, entry.measuredAt),
      formatWeight(entry.weightGrams, kg: l10n.unitKg, g: l10n.unitGrams),
    ],
];

List<List<String>> visitRows(
  AppLocalizations l10n,
  String localeTag,
  List<VetVisit> visits,
) => <List<String>>[
  for (final VetVisit visit in visits)
    <String>[
      formatDayOrUnknown(l10n, localeTag, visit.visitDate),
      visit.reason ?? l10n.visitNoReason,
      visit.outcome ?? l10n.valueUnknown,
    ],
];

/// What the breeder saw, in the buyer's document too: a symptom is the least
/// verifiable line in this record and the one most likely to be left out of a
/// paper summary, so it gets a table rather than a sentence in the notes.
List<List<String>> symptomRows(
  AppLocalizations l10n,
  String localeTag,
  List<Symptom> sightings,
) => <List<String>>[
  for (final Symptom symptom in sightings)
    <String>[
      symptom.label,
      formatDayOrUnknown(l10n, localeTag, symptom.observedAt),
      severityLabel(l10n, symptom.severity),
      symptom.ongoing ? l10n.symptomOngoing : l10n.symptomResolved,
      symptom.note ?? l10n.valueUnknown,
    ],
];

/// `subjectId` is the animal the document is about: the litter row has to say
/// which side of the pedigree it stood on, and only the caller knows whose page
/// this is.
List<List<String>> breedingRows(
  AppLocalizations l10n,
  String localeTag,
  String subjectId,
  List<LitterOutcome> outcomes,
) => <List<String>>[
  for (final LitterOutcome outcome in outcomes)
    <String>[
      outcome.litter.name,
      // Which side of the pedigree this animal stood on, because a sire's value
      // on paper is exactly the litters he got.
      outcome.litter.damId == subjectId ? l10n.animalDam : l10n.animalSire,
      formatDayOrUnknown(l10n, localeTag, outcome.litter.whelpingDate),
      '${outcome.puppies}',
    ],
];

/// Who took the animal home, and what they were promised.
///
/// Every handover is printed, not the newest one: `PlacementDao.forAnimal` orders
/// by `placed_date DESC`, and SQLite puts a null last in a descending sort, so
/// reading only `first` dropped the handover whose date the breeder had not
/// written yet — and the one document that should say who has the dog now was
/// saying it about the previous family instead.
List<(String, String)> placementFacts(
  AppLocalizations l10n,
  String localeTag,
  Placement placement,
  Buyer? buyer,
) => <(String, String)>[
  (l10n.pdfBuyer, buyer?.name ?? l10n.valueUnknown),
  // A contact line that cannot be filled gets no line at all — the same rule the
  // country and the guarantee follow, and the one these two were missing: a buyer
  // whose email arrived as the empty string from a restored pack printed its
  // label over a blank.
  if (buyer?.phone case final String phone when phone.isNotEmpty)
    (l10n.pdfPhone, phone),
  if (buyer?.email case final String email when email.isNotEmpty)
    (l10n.pdfEmail, email),
  // Where the family is. A health guarantee is enforced against a person at an
  // address, and this line is the only trace of either in the document.
  if (buyer?.countryCode case final String country when country.isNotEmpty)
    (l10n.buyerCountryCode, country),
  (l10n.pdfPlacedOn, formatDayOrUnknown(l10n, localeTag, placement.placedDate)),
  (
    l10n.pdfPrice,
    formatPriceWithCurrency(
      placement.price,
      placement.currency,
      unknown: l10n.valueUnknown,
    ),
  ),
  if (placement.guaranteeTerms != null && placement.guaranteeTerms!.isNotEmpty)
    (l10n.pdfGuarantee, placement.guaranteeTerms!),
];
