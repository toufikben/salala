import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/l10n/app_localizations.dart';
import '../core/l10n/enum_labels.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/weight.dart';
import '../data/db/daos.dart';
import '../data/models/animal.dart';
import '../data/models/health_test.dart';
import '../data/models/litter.dart';
import '../data/models/placement.dart';
import '../data/models/vaccination.dart';
import '../data/models/vet_visit.dart';
import '../data/models/weight_entry.dart';

const double _dayMs = 86400000.0;

/// The face the document embeds, declared in `pubspec.yaml` as an asset.
///
/// Named here because the caller only has to load it: `pdf` draws a glyph the
/// chosen font lacks as an empty box rather than raising, so a document built
/// without this file is silently unreadable in Arabic (D24).
const String pdfFontAsset = 'assets/fonts/Amiri-Regular.ttf';

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

  final litters = await _everyLitterOf(daos, animal.id);
  final litterRows = <List<String>>[];
  for (final Litter litter in litters) {
    final puppies = await daos.animals.findOffspring(litter.id);
    litterRows.add(<String>[
      litter.name,
      // Which side of the pedigree this animal stood on, because a sire's value
      // on paper is exactly the litters he got.
      litter.damId == animal.id ? l10n.animalDam : l10n.animalSire,
      _day(l10n, localeTag, litter.whelpingDate),
      '${puppies.length}',
    ]);
  }

  final pedigree = await _ancestry(l10n, daos, animal, 1, <String>{animal.id});

  final placements = await daos.placements.forAnimal(animal.id);
  final Placement? placement = placements.isEmpty ? null : placements.first;
  final buyerId = placement?.buyerId;
  final buyer = buyerId == null ? null : await daos.buyers.findById(buyerId);

  final chart = _growthChart(animal, weighIns);

  final body = <pw.Widget>[
    pw.Text(
      animal.name,
      style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
    ),
    pw.Text(
      l10n.pdfTitle,
      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
    ),
    pw.Text(
      l10n.pdfGenerated(formatDayFor(localeTag, generatedAt)),
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
    ),
    pw.SizedBox(height: 10),
    _facts(<(String, String)>[
      (l10n.animalSpecies, animal.species),
      (l10n.animalBreed, animal.breed ?? l10n.valueUnknown),
      (l10n.animalSex, sexLabel(l10n, animal.sex)),
      (l10n.animalStatus, statusLabel(l10n, animal.status)),
      (l10n.animalBirthDate, _day(l10n, localeTag, animal.birthDate)),
      if (animal.deathDate != null)
        (l10n.animalDeathDate, _day(l10n, localeTag, animal.deathDate)),
      (l10n.animalColor, animal.color ?? l10n.valueUnknown),
      (l10n.animalRegistrationNo, animal.registrationNo ?? l10n.valueUnknown),
      (l10n.animalRegistry, animal.registry ?? l10n.valueUnknown),
      (l10n.animalMicrochip, animal.microchipId ?? l10n.valueUnknown),
    ]),
    ..._section(
      l10n.pdfPedigree,
      pedigree.isEmpty ? <pw.Widget>[pw.Text(l10n.valueUnknown)] : pedigree,
    ),
    ..._table(
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
            _day(l10n, localeTag, dose.dateAdministered),
            _day(l10n, localeTag, dose.nextDueDate),
            dose.vetName ?? l10n.valueUnknown,
          ],
      ],
    ),
    ..._table(
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
            _day(l10n, localeTag, test.testDate),
            _day(l10n, localeTag, test.validUntil),
          ],
      ],
    ),
    ..._table(
      l10n,
      l10n.recordsWeights,
      <String>[l10n.weightMeasuredOn, l10n.weightKg],
      <List<String>>[
        for (final WeightEntry entry in weighIns)
          <String>[
            _day(l10n, localeTag, entry.measuredAt),
            formatWeight(entry.weightGrams, kg: l10n.unitKg, g: l10n.unitGrams),
          ],
      ],
      trailing: chart == null
          ? const <pw.Widget>[]
          : <pw.Widget>[pw.SizedBox(height: 8), chart],
    ),
    ..._table(
      l10n,
      l10n.recordsVisits,
      <String>[l10n.visitDate, l10n.visitReason, l10n.visitOutcome],
      <List<String>>[
        for (final VetVisit visit in visits)
          <String>[
            _day(l10n, localeTag, visit.visitDate),
            visit.reason ?? l10n.visitNoReason,
            visit.outcome ?? l10n.valueUnknown,
          ],
      ],
    ),
    ..._table(l10n, l10n.pdfLitters, <String>[
      l10n.litterName,
      l10n.animalSex,
      l10n.litterWhelpingDate,
      l10n.pdfPuppies,
    ], litterRows),
    if (placement != null)
      ..._section(l10n.pdfPlacement, <pw.Widget>[
        _facts(<(String, String)>[
          (l10n.pdfBuyer, buyer?.name ?? l10n.valueUnknown),
          if (buyer?.phone != null) (l10n.pdfPhone, buyer!.phone!),
          if (buyer?.email != null) (l10n.pdfEmail, buyer!.email!),
          (l10n.pdfPlacedOn, _day(l10n, localeTag, placement.placedDate)),
          (
            l10n.pdfPrice,
            placement.price == null
                ? l10n.valueUnknown
                : '${placement.price!.toStringAsFixed(2)} '
                          '${placement.currency ?? ''}'
                      .trim(),
          ),
          if (placement.guaranteeTerms != null &&
              placement.guaranteeTerms!.isNotEmpty)
            (l10n.pdfGuarantee, placement.guaranteeTerms!),
        ]),
      ]),
    if (animal.notes != null && animal.notes!.isNotEmpty)
      ..._section(l10n.animalNotes, <pw.Widget>[pw.Text(animal.notes!)]),
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
      footer: (context) => pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Text(
          animal.name,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (context) => body,
    ),
  );

  return document.save();
}

/// A heading and whatever is known about one subject.
List<pw.Widget> _section(String title, List<pw.Widget> body) => <pw.Widget>[
  pw.SizedBox(height: 14),
  pw.Text(
    title,
    style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
  ),
  pw.SizedBox(height: 4),
  ...body,
];

/// Records in a bordered grid, or the sentence that says there are none.
///
/// An empty table on a document someone keeps is worse than that sentence: it
/// reads as a section the app left out, not as a record with nothing in it.
List<pw.Widget> _table(
  AppLocalizations l10n,
  String title,
  List<String> headings,
  List<List<String>> rows, {
  List<pw.Widget> trailing = const <pw.Widget>[],
}) => _section(title, <pw.Widget>[
  if (rows.isEmpty)
    pw.Text(l10n.recordsEmpty)
  else
    pw.Table(
      defaultColumnWidth: const pw.FlexColumnWidth(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: <pw.TableRow>[
        _row(headings, strong: true),
        for (final List<String> row in rows) _row(row),
      ],
    ),
  ...trailing,
]);

/// Label and value in two columns, for the facts that are not a history.
pw.Widget _facts(List<(String, String)> facts) => pw.Table(
  defaultColumnWidth: const pw.FlexColumnWidth(2),
  columnWidths: const <int, pw.TableColumnWidth>{0: pw.FlexColumnWidth(1)},
  children: <pw.TableRow>[
    for (final (label, value) in facts) _row(<String>[label, value]),
  ],
);

pw.TableRow _row(List<String> cells, {bool strong = false}) => pw.TableRow(
  children: <pw.Widget>[
    for (final String cell in cells)
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(
          cell,
          style: strong
              ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
              : null,
        ),
      ),
  ],
);

/// Weight against age — the one curve a puppy's owner reads off a list of
/// numbers. Left out rather than drawn on an invented axis: without a birth date
/// there is no age, and two weigh-ins on one day, or at one weight, leave a fixed
/// axis with a single mark to place.
pw.Widget? _growthChart(Animal animal, List<WeightEntry> weighIns) {
  final birthDate = animal.birthDate;
  if (birthDate == null || weighIns.length < 2) return null;

  final points = <pw.PointChartValue>[
    for (final WeightEntry entry in weighIns)
      pw.PointChartValue<double>(
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

/// A date a breeder can line up against a paper certificate, or the words for
/// "never written down". A blank cell reads as something the app withheld; the
/// gap in the record has to be named out loud.
String _day(AppLocalizations l10n, String localeTag, int? epochMs) {
  final day = formatDayFor(localeTag, epochMs);
  return day.isEmpty ? l10n.valueUnknown : day;
}
