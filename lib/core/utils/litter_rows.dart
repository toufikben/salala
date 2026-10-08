/// The rows a whelping record prints, worked out apart from the page.
///
/// The document writer takes rows of text and lays them out; this file decides
/// what goes in them. Splitting the two is what lets CI check the words — a PDF
/// draws its letters through the embedded font's glyph ids, so a test over the
/// bytes cannot read a single line back. What stays here is arithmetic, dates and
/// labels: everything a breeder would notice as wrong on paper.
library;

import '../../data/models/animal.dart';
import '../../data/models/buyer.dart';
import '../../data/models/placement.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/weight_entry.dart';
import '../l10n/app_localizations.dart';
import '../l10n/enum_labels.dart';
import 'date_utils.dart';
import 'money.dart';
import 'weight.dart';

/// One puppy and the records written about it.
///
/// The caller reads them and hands them over, because a whelping record covers a
/// dozen animals at once and a document that queried the database from inside a
/// table row would be a query per cell.
class LitterPuppy {
  const LitterPuppy({
    required this.animal,
    required this.doses,
    required this.weighIns,
    required this.placements,
  });

  final Animal animal;

  /// Newest first, the order `VaccinationDao.forAnimal` returns.
  final List<Vaccination> doses;

  /// Oldest first, the order `WeightDao.forAnimal` returns.
  final List<WeightEntry> weighIns;

  /// Newest first, and every handover the puppy has — the newest one may simply
  /// have no date written yet.
  final List<Placement> placements;

  WeightEntry? get latestWeighIn => weighIns.isEmpty ? null : weighIns.last;
}

/// The mating and the dates around it, as label and value.
///
/// A gap is printed as the app's own "unknown", not as a blank: on this page a
/// blank cell reads as a whelping that never happened rather than a date nobody
/// typed.
List<(String, String)> whelpingFacts(
  AppLocalizations l10n,
  String localeTag, {
  required String damName,
  required String? sireName,
  required int? matingDate,
  required int? whelpingDate,
  required int? weaningDate,
}) => <(String, String)>[
  (l10n.litterDam, damName),
  (
    l10n.litterSire,
    // A missing sire and a sire whose animal row was deleted are the same words
    // on paper, and neither is a blank the reader has to guess about.
    sireName ?? l10n.litterSireUnknown,
  ),
  (l10n.litterMatingDate, formatDayOrUnknown(l10n, localeTag, matingDate)),
  (l10n.litterWhelpingDate, formatDayOrUnknown(l10n, localeTag, whelpingDate)),
  (l10n.litterWeaningDate, formatDayOrUnknown(l10n, localeTag, weaningDate)),
];

/// One row per puppy: who they are, how they grew, where they stand.
///
/// The weigh-in is the newest one only. A whelping box is weighed daily, so every
/// puppy's whole curve on one page would push the list of puppies off the paper —
/// and the curve belongs to the animal's own document, which the family keeps.
List<List<String>> puppyRows(
  AppLocalizations l10n,
  String localeTag,
  List<LitterPuppy> puppies,
) => <List<String>>[
  for (final LitterPuppy puppy in puppies)
    <String>[
      puppy.animal.name,
      sexLabel(l10n, puppy.animal.sex),
      formatDayOrUnknown(l10n, localeTag, puppy.animal.birthDate),
      statusLabel(l10n, puppy.animal.status),
      _weighIn(l10n, puppy.latestWeighIn),
    ],
];

/// The doses the litter has had, one row per dose, puppy named first.
///
/// A round given to the whole litter is five rows with the same vaccine and the
/// same day, which is exactly what a vet wants to see: the puppy missing from the
/// list is the one that was skipped.
List<List<String>> doseRows(
  AppLocalizations l10n,
  String localeTag,
  List<LitterPuppy> puppies,
) => <List<String>>[
  for (final LitterPuppy puppy in puppies)
    for (final Vaccination dose in puppy.doses)
      <String>[
        puppy.animal.name,
        dose.vaccineName,
        formatDayOrUnknown(l10n, localeTag, dose.dateAdministered),
        formatDayOrUnknown(l10n, localeTag, dose.nextDueDate),
        dose.vetName ?? l10n.valueUnknown,
      ],
];

/// Who took each puppy home, one row per handover, in puppy order.
///
/// The contacts come in as a list rather than a lookup per row, in the order the
/// app lists people in. A placement whose buyer id answers to nobody is still
/// printed — the handover happened, and the name is what is missing.
List<List<String>> handoverRows(
  AppLocalizations l10n,
  String localeTag,
  List<LitterPuppy> puppies,
  List<Buyer> buyers,
) => <List<String>>[
  for (final LitterPuppy puppy in puppies)
    for (final Placement placement in puppy.placements)
      <String>[
        puppy.animal.name,
        buyerById(buyers, placement.buyerId)?.name ?? l10n.placementNoBuyer,
        formatDayOrUnknown(l10n, localeTag, placement.placedDate),
        formatPriceWithCurrency(
          placement.price,
          placement.currency,
          unknown: l10n.valueUnknown,
        ),
      ],
];

String _weighIn(AppLocalizations l10n, WeightEntry? entry) {
  if (entry == null) return l10n.valueUnknown;
  return formatWeight(entry.weightGrams, kg: l10n.unitKg, g: l10n.unitGrams);
}
