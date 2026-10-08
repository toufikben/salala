import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/l10n/app_localizations.dart';
import '../core/l10n/enum_labels.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/money.dart';
import '../core/utils/weight.dart';
import '../data/db/daos.dart';
import '../data/models/animal.dart';
import '../data/models/buyer.dart';
import '../data/models/health_test.dart';
import '../data/models/litter.dart';
import '../data/models/placement.dart';
import '../data/models/symptom.dart';
import '../data/models/vaccination.dart';
import '../data/models/vet_visit.dart';
import '../data/models/weight_entry.dart';
import 'pdf_layout.dart';

const double _dayMs = 86400000.0;

/// The record a buyer keeps (Stage 2).
///
/// The JSON pack is for the breeder's own phone. This document is for the other
/// end of a sale: the person who paid for a puppy and still wants its rabies date
/// in six years, on a device that will never run Salala. PDF is chosen because it
/// survives an email, a print shop and a change of phone.
///
/// Every line here is written from rows the breeder typed, which is why the
/// document ends with [AppLocalizations.pdfDisclaimer] instead of a signature
/// line. The app verified none of it, and a stamp of approval over unverified
/// health data is how a guarantee becomes a dispute.
///
/// All reads happen before the page is described: the document's `build`
/// callback is synchronous, so a section that needed the database would have to
/// be awaited by whoever asked for the page.
Future<Uint8List> animalPackPdf(
  Daos daos, {
  required String animalId,
  required AppLocalizations l10n,
  required ByteData baseFont,
  DateTime? now,
}) async {
  final animal = await daos.animals.findById(animalId);
  if (animal == null) {
    // The action sits on the animal's own page, so reaching here means the row
    // was deleted while the page was open. Say that instead of writing a blank.
    throw StateError('There is no animal $animalId to describe');
  }

  final localeTag = l10n.localeName;
  // The bundled font carries Arabic presentation forms and `pdf` shapes nothing
  // itself, so the page direction is what makes Arabic on this document readable
  // at all — see DECISIONS.md D24.
  final direction = localeTag.startsWith('ar')
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;
  final generatedAt = (now ?? DateTime.now()).millisecondsSinceEpoch;

  final doses = await daos.vaccinations.forAnimal(animal.id);
  final screenings = await daos.healthTests.forAnimal(animal.id);
  final visits = await daos.vetVisits.forAnimal(animal.id);
  final weighIns = await daos.weights.forAnimal(animal.id);
  final sightings = await daos.symptoms.forAnimal(animal.id);

  final litters = await _everyLitterOf(daos, animal.id);
  final litterRows = <List<String>>[];
  for (final Litter litter in litters) {
    final puppies = await daos.animals.findOffspring(litter.id);
    litterRows.add(<String>[
      litter.name,
      // Which side of the pedigree this animal stood on, because a sire's value
      // on paper is exactly the litters he got.
      litter.damId == animal.id ? l10n.animalDam : l10n.animalSire,
      formatDayOrUnknown(l10n, localeTag, litter.whelpingDate),
      '${puppies.length}',
    ]);
  }

  final pedigree = await _ancestry(l10n, daos, animal, 1, <String>{animal.id});

  // Every handover, not the newest one. `forAnimal` orders by `placed_date DESC`,
  // and SQLite puts a null last in a descending sort, so reading only `first`
  // dropped a handover whose date the breeder had not written yet — the one
  // document that should say who has the dog now was saying it about the previous
  // family instead. The contacts they name come from one read, not a query per
  // row, in the order the app lists people in.
  final placements = await daos.placements.forAnimal(animal.id);
  final buyers = placements.isEmpty
      ? const <Buyer>[]
      : await daos.buyers.alphabetical();

  final chart = _growthChart(animal, weighIns);

  final body = <pw.Widget>[
    ...pdfMasthead(
      name: animal.name,
      kind: l10n.pdfTitle,
      generatedLine: l10n.pdfGenerated(formatDayFor(localeTag, generatedAt)),
    ),
    pdfFacts(<(String, String)>[
      (l10n.animalSpecies, animal.species),
      (l10n.animalBreed, animal.breed ?? l10n.valueUnknown),
      (l10n.animalSex, sexLabel(l10n, animal.sex)),
      (l10n.animalStatus, statusLabel(l10n, animal.status)),
      (
        l10n.animalBirthDate,
        formatDayOrUnknown(l10n, localeTag, animal.birthDate),
      ),
      if (animal.deathDate != null)
        (
          l10n.animalDeathDate,
          formatDayOrUnknown(l10n, localeTag, animal.deathDate),
        ),
      (l10n.animalColor, animal.color ?? l10n.valueUnknown),
      (l10n.animalRegistrationNo, animal.registrationNo ?? l10n.valueUnknown),
      (l10n.animalRegistry, animal.registry ?? l10n.valueUnknown),
      (l10n.animalMicrochip, animal.microchipId ?? l10n.valueUnknown),
    ]),
    ...pdfSection(
      l10n.pdfPedigree,
      pedigree.isEmpty ? <pw.Widget>[pw.Text(l10n.valueUnknown)] : pedigree,
    ),
    ...pdfTable(
      l10n,
      l10n.recordsVaccinations,
      <String>[
        l10n.vaccinationName,
        l10n.vaccinationGiven,
        l10n.vaccinationNextDue,
        l10n.vaccinationVet,
      ],
      <List<String>>[
        for (final Vaccination dose in doses)
          <String>[
            dose.vaccineName,
            formatDayOrUnknown(l10n, localeTag, dose.dateAdministered),
            formatDayOrUnknown(l10n, localeTag, dose.nextDueDate),
            dose.vetName ?? l10n.valueUnknown,
          ],
      ],
    ),
    ...pdfTable(
      l10n,
      l10n.recordsHealthTests,
      <String>[
        l10n.healthTestType,
        l10n.healthTestResult,
        l10n.healthTestDate,
        l10n.healthTestValidUntil,
      ],
      <List<String>>[
        for (final HealthTest test in screenings)
          <String>[
            test.testType,
            test.result,
            formatDayOrUnknown(l10n, localeTag, test.testDate),
            formatDayOrUnknown(l10n, localeTag, test.validUntil),
          ],
      ],
    ),
    ...pdfTable(
      l10n,
      l10n.recordsWeights,
      <String>[l10n.weightMeasuredOn, l10n.weightKg],
      <List<String>>[
        for (final WeightEntry entry in weighIns)
          <String>[
            formatDayOrUnknown(l10n, localeTag, entry.measuredAt),
            formatWeight(entry.weightGrams, kg: l10n.unitKg, g: l10n.unitGrams),
          ],
      ],
      trailing: chart == null
          ? const <pw.Widget>[]
          : <pw.Widget>[pw.SizedBox(height: 8), chart],
    ),
    ...pdfTable(
      l10n,
      l10n.recordsVisits,
      <String>[l10n.visitDate, l10n.visitReason, l10n.visitOutcome],
      <List<String>>[
        for (final VetVisit visit in visits)
          <String>[
            formatDayOrUnknown(l10n, localeTag, visit.visitDate),
            visit.reason ?? l10n.visitNoReason,
            visit.outcome ?? l10n.valueUnknown,
          ],
      ],
    ),
    // What the breeder saw, in the buyer's document too: a symptom is the least
    // verifiable line in this record and the one most likely to be left out of a
    // paper summary, so it gets a table rather than a sentence in the notes.
    ...pdfTable(
      l10n,
      l10n.recordsSymptoms,
      <String>[
        l10n.symptomName,
        l10n.symptomObservedOn,
        l10n.symptomSeverity,
        l10n.symptomState,
        l10n.animalNotes,
      ],
      <List<String>>[
        for (final Symptom symptom in sightings)
          <String>[
            symptom.label,
            formatDayOrUnknown(l10n, localeTag, symptom.observedAt),
            severityLabel(l10n, symptom.severity),
            symptom.ongoing ? l10n.symptomOngoing : l10n.symptomResolved,
            symptom.note ?? l10n.valueUnknown,
          ],
      ],
    ),
    ...pdfTable(l10n, l10n.pdfLitters, <String>[
      l10n.litterName,
      l10n.animalSex,
      l10n.litterWhelpingDate,
      l10n.pdfPuppies,
    ], litterRows),
    for (final placement in placements)
      ..._placementBlock(
        l10n,
        localeTag,
        placement,
        buyerById(buyers, placement.buyerId),
      ),
    if (animal.notes != null && animal.notes!.isNotEmpty)
      ...pdfSection(l10n.animalNotes, <pw.Widget>[pw.Text(animal.notes!)]),
    pw.SizedBox(height: 18),
    pw.Text(
      l10n.pdfDisclaimer,
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
    ),
  ];

  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: pw.Font.ttf(baseFont)),
      margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 40),
      textDirection: direction,
      maxPages: 40,
      footer: (context) => pdfFooter(animal.name),
      build: (context) => body,
    ),
  );

  return document.save();
}

/// What one family took home, and who they are.
///
/// Its own function because a handover is now printed for *every* placement the
/// animal has, and the buyer behind it has to be looked up once rather than once
/// per line.
List<pw.Widget> _placementBlock(
  AppLocalizations l10n,
  String localeTag,
  Placement placement,
  Buyer? buyer,
) => pdfSection(l10n.pdfPlacement, <pw.Widget>[
  pdfFacts(<(String, String)>[
    (l10n.pdfBuyer, buyer?.name ?? l10n.valueUnknown),
    if (buyer?.phone != null) (l10n.pdfPhone, buyer!.phone!),
    if (buyer?.email != null) (l10n.pdfEmail, buyer!.email!),
    // Where the family is. A health guarantee is enforced against a person at an
    // address, and this line is the only trace of either in the document.
    if (buyer?.countryCode case final String country when country.isNotEmpty)
      (l10n.buyerCountryCode, country),
    (
      l10n.pdfPlacedOn,
      formatDayOrUnknown(l10n, localeTag, placement.placedDate),
    ),
    (
      l10n.pdfPrice,
      formatPriceWithCurrency(
        placement.price,
        placement.currency,
        unknown: l10n.valueUnknown,
      ),
    ),
    if (placement.guaranteeTerms != null &&
        placement.guaranteeTerms!.isNotEmpty)
      (l10n.pdfGuarantee, placement.guaranteeTerms!),
  ]),
]);

/// Weight against age — the one curve a puppy's owner reads off a list of
/// numbers. Left out rather than drawn on an invented axis: without a birth date
/// there is no age, and two weigh-ins on one day, or at one weight, leave a fixed
/// axis with a single mark to place.
pw.Widget? _growthChart(Animal animal, List<WeightEntry> weighIns) {
  final birthDate = animal.birthDate;
  if (birthDate == null || weighIns.length < 2) return null;

  final points = <pw.PointChartValue>[
    for (final WeightEntry entry in weighIns)
      pw.PointChartValue(
        (entry.measuredAt - birthDate) / _dayMs,
        entry.weightKg,
      ),
  ];
  final days =
      points.map((pw.PointChartValue point) => point.x).toSet().toList()
        ..sort();
  final kilos =
      points.map((pw.PointChartValue point) => point.y).toSet().toList()
        ..sort();
  if (days.length < 2 || kilos.length < 2) return null;

  return pw.SizedBox(
    height: 170,
    child: pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis<double>(days),
        yAxis: pw.FixedAxis<double>(kilos),
      ),
      datasets: <pw.Dataset>[
        pw.LineDataSet<pw.PointChartValue>(
          data: points,
          color: PdfColors.blueGrey700,
        ),
      ],
    ),
  );
}

/// Parents, then grandparents, then great-grandparents, nested so the indent
/// comes from the layout rather than from spaces a bidi pass would move.
///
/// Three generations and no further: past that the page would be asserting
/// ancestry nobody recorded. [seen] stops a ledger that names an animal as its
/// own ancestor from being walked for ever.
Future<List<pw.Widget>> _ancestry(
  AppLocalizations l10n,
  Daos daos,
  Animal subject,
  int generation,
  Set<String> seen,
) async {
  if (generation > 3) return const <pw.Widget>[];

  final rows = <pw.Widget>[];
  for (final (label, id) in <(String, String?)>[
    (l10n.animalDam, subject.damId),
    (l10n.animalSire, subject.sireId),
  ]) {
    if (id == null) continue;
    final parent = await daos.animals.findById(id);
    if (parent == null) continue;

    final above = seen.add(parent.id)
        ? await _ancestry(l10n, daos, parent, generation + 1, seen)
        : const <pw.Widget>[];
    rows.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            '$label: ${parent.name}'
            '${parent.breed == null ? '' : ' · ${parent.breed}'}',
          ),
          ...above,
        ],
      ),
    );
  }
  return rows;
}

/// Every litter this animal produced or sired, newest whelping first.
Future<List<Litter>> _everyLitterOf(Daos daos, String animalId) async {
  final byId = <String, Litter>{
    for (final Litter litter in <Litter>[
      ...await daos.litters.forDam(animalId),
      ...await daos.litters.forSire(animalId),
    ])
      litter.id: litter,
  };
  final sorted = byId.values.toList()
    ..sort(
      (Litter a, Litter b) =>
          (b.whelpingDate ?? 0).compareTo(a.whelpingDate ?? 0),
    );
  return sorted;
}
