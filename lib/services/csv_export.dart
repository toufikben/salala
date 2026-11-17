/// The ledger as a spreadsheet: one row per record, ready for Excel or Numbers.
///
/// A backup is for getting the ledger *back*; a CSV is for getting it *out* —
/// into the accountant's sheet, the registry form, the email to a co-owner. They
/// answer different questions, which is why this is a second export rather than
/// another setting on the pack.
///
/// Three things decide the shape of every file here:
/// * **CRLF and a BOM.** Excel on Windows needs the byte-order mark to read
///   Arabic or French accents without turning them into `Ø£`, and it splits rows
///   on CRLF. Both are in the file whether or not the reader is Excel.
/// * **Every cell is escaped by one rule**, so a name with a comma in it cannot
///   shift a column and a note with a newline cannot break a row.
/// * **A cell that would start a formula is defused.** A breeder's note reading
///   `=1+1`, or a name pasted from someone else, must arrive as text: a file that
///   runs `=HYPERLINK(...)` on open is a document that does something to the
///   person who asked only to look at their own dogs.
library;

import '../core/l10n/app_localizations.dart';
import '../core/l10n/enum_labels.dart';
import '../data/models/animal.dart';
import '../data/models/buyer.dart';
import '../data/models/litter.dart';
import '../data/models/placement.dart';
import '../data/models/vaccination.dart';

/// The byte-order mark Excel needs before it will read UTF-8 as UTF-8.
const String csvBom = '\uFEFF';

/// One cell, quoted if it has to be and defused if it could run.
///
/// `=`, `@` and a leading tab or carriage return are the openers a spreadsheet
/// still executes. `+` and `-` are deliberately left alone, because a phone
/// number written `+212…` and a negative correction are ordinary data, and
/// prefixing them would put stray apostrophes through a column the breeder reads
/// every day.
String csvCell(String? value) {
  if (value == null || value.isEmpty) return '';
  var text = value;
  if (text.startsWith('=') ||
      text.startsWith('@') ||
      text.startsWith('\t') ||
      text.startsWith('\r')) {
    text = "'$text";
  }
  final needsQuotes =
      text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r');
  if (!needsQuotes) return text;
  return '"${text.replaceAll('"', '""')}"';
}

/// One row, ended the way Excel expects.
String csvRow(List<String?> cells) => '${cells.map(csvCell).join(',')}\r\n';

/// A whole file: the mark, the header, the rows.
String csvFile(List<String> header, Iterable<List<String?>> rows) {
  final buffer = StringBuffer(csvBom)..write(csvRow(header));
  for (final row in rows) {
    buffer.write(csvRow(row));
  }
  return buffer.toString();
}

/// A stored instant as `yyyy-mm-dd` in the phone's own time zone, or blank.
///
/// The ledger stores a date as midnight-local in unix milliseconds, so reading
/// it back has to go through the local zone or a breeder east of Greenwich gets
/// yesterday's birthday. Blank rather than an epoch date: a missing birth date is
/// missing, and `1970-01-01` in a registry form is a lie the app invented.
String csvDay(int? ms) {
  if (ms == null) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// The herd, one row per animal, with the parents written as names.
///
/// Names rather than ids because the file is read by a person other than the
/// app: `a-3f9c…` in a "Sire" column means nothing on paper.
///
/// Every heading is the same word the form uses for that field, taken from
/// [l10n] rather than typed here: an export read by a co-owner in French has to
/// be a French sheet, and a heading spelled into this file was a second place
/// the app's own vocabulary had to be kept in step. The values follow the same
/// rule — `status.name` would have printed `active` in every language.
String herdCsv(List<Animal> animals, AppLocalizations l10n) {
  String nameOf(String? id) => animalById(animals, id)?.name ?? '';

  return csvFile(
    <String>[
      l10n.animalName,
      l10n.animalSpecies,
      l10n.animalBreed,
      l10n.animalSex,
      l10n.animalStatus,
      l10n.animalBirthDate,
      l10n.animalDeathDate,
      l10n.animalColor,
      l10n.animalRegistrationNo,
      l10n.animalRegistry,
      l10n.animalMicrochip,
      l10n.animalDam,
      l10n.animalSire,
      l10n.csvColBreedingStock,
      l10n.animalNotes,
    ],
    animals.map(
      (animal) => <String?>[
        animal.name,
        animal.species,
        animal.breed,
        sexLabel(l10n, animal.sex),
        statusLabel(l10n, animal.status),
        csvDay(animal.birthDate),
        csvDay(animal.deathDate),
        animal.color,
        animal.registrationNo,
        animal.registry,
        animal.microchipId,
        nameOf(animal.damId),
        nameOf(animal.sireId),
        animal.isBreedingStock ? l10n.csvColYes : l10n.csvColNo,
        animal.notes,
      ],
    ),
  );
}

/// Every whelping, newest first, with the puppies already registered counted in.
String littersCsv(
  List<Litter> litters,
  List<Animal> animals,
  AppLocalizations l10n,
) {
  String nameOf(String? id) => animalById(animals, id)?.name ?? '';

  final ordered = <Litter>[...litters]
    ..sort((a, b) => (b.whelpingDate ?? 0).compareTo(a.whelpingDate ?? 0));

  return csvFile(
    <String>[
      l10n.litterName,
      l10n.litterDam,
      l10n.litterSire,
      l10n.litterMatingDate,
      l10n.litterWhelpingDate,
      l10n.litterWeaningDate,
      l10n.csvColPuppies,
      l10n.animalNotes,
    ],
    ordered.map(
      (litter) => <String?>[
        litter.name,
        nameOf(litter.damId),
        nameOf(litter.sireId),
        csvDay(litter.matingDate),
        csvDay(litter.whelpingDate),
        csvDay(litter.weaningDate),
        '${puppiesOf(animals, litter.id).length}',
        litter.notes,
      ],
    ),
  );
}

/// Every dose on this phone, newest first as the ledger shows them.
String vaccinationsCsv(
  List<Vaccination> doses,
  List<Animal> animals,
  AppLocalizations l10n,
) {
  String nameOf(String? id) => animalById(animals, id)?.name ?? '';

  final ordered = <Vaccination>[...doses]
    ..sort((a, b) => b.dateAdministered.compareTo(a.dateAdministered));

  return csvFile(
    <String>[
      l10n.csvColAnimal,
      l10n.vaccinationName,
      l10n.vaccinationGiven,
      l10n.vaccinationNextDue,
      l10n.vaccinationManufacturer,
      l10n.vaccinationBatch,
      l10n.vaccinationVet,
      l10n.vaccinationClinic,
      l10n.vaccinationCertificate,
    ],
    ordered.map(
      (dose) => <String?>[
        nameOf(dose.animalId),
        dose.vaccineName,
        csvDay(dose.dateAdministered),
        csvDay(dose.nextDueDate),
        dose.manufacturer,
        dose.batchNumber,
        dose.vetName,
        dose.clinicName,
        dose.certificateNumber,
      ],
    ),
  );
}

/// Every handover, which is the money side of the ledger.
///
/// The buyer is written by name and country rather than by id: this file is what
/// a breeder hands to an accountant, and an accountant cannot look up `b-7`.
String placementsCsv(
  List<Placement> placements,
  List<Animal> animals,
  List<Buyer> buyers,
  AppLocalizations l10n,
) {
  String animalName(String id) => animalById(animals, id)?.name ?? '';

  final ordered = <Placement>[...placements]
    ..sort((a, b) => (b.placedDate ?? 0).compareTo(a.placedDate ?? 0));

  return csvFile(
    <String>[
      l10n.csvColAnimal,
      l10n.placementBuyer,
      l10n.csvColCountry,
      l10n.placementDate,
      l10n.placementPrice,
      l10n.placementCurrency,
      l10n.placementGuarantee,
      l10n.animalNotes,
    ],
    ordered.map((placement) {
      final buyer = buyerById(buyers, placement.buyerId);
      return <String?>[
        animalName(placement.animalId),
        buyer?.name,
        buyer?.countryCode,
        csvDay(placement.placedDate),
        // A price is written the way a spreadsheet reads a number, with a dot:
        // a comma here would be a column break in half the world's locales.
        placement.price?.toString(),
        placement.currency,
        placement.guaranteeTerms,
        placement.notes,
      ];
    }),
  );
}
