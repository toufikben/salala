import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/l10n/app_localizations.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/litter_rows.dart';
import '../data/db/daos.dart';
import '../data/models/animal.dart';
import '../data/models/buyer.dart';
import '../data/models/litter.dart';
import 'pdf_layout.dart';

/// The whelping record (Stage 2): one page for a whole litter.
///
/// The animal's own pack answers "what did this puppy have?". This answers the
/// question the breeder asks at the whelping box and at the vet's desk instead:
/// how many were born, who the parents were, which puppies had the 8-week round
/// and which did not, and who took each one home. Nobody else keeps this page —
/// it is the record of an event, not of an animal.
///
/// Every read happens before the page is described, because the document's
/// `build` callback is synchronous.
Future<Uint8List> litterPackPdf(
  Daos daos, {
  required String litterId,
  required AppLocalizations l10n,
  required ByteData baseFont,
  DateTime? now,
}) async {
  final Litter litter = await daos.litters.findById(litterId);
  if (litter == null) {
    // The action sits on the litter's own page, so reaching here means the row
    // was deleted while the page was open.
    throw StateError('There is no litter $litterId to describe');
  }

  final localeTag = l10n.localeName;
  final direction = localeTag.startsWith('ar')
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;
  final generatedAt = (now ?? DateTime.now()).millisecondsSinceEpoch;

  final Animal? dam = await daos.animals.findById(litter.damId);
  final Animal? sire = litter.sireId == null
      ? null
      : await daos.animals.findById(litter.sireId);

  final puppies = <LitterPuppy>[];
  for (final Animal puppy in await daos.animals.findOffspring(litter.id)) {
    puppies.add(
      LitterPuppy(
        animal: puppy,
        doses: await daos.vaccinations.forAnimal(puppy.id),
        weighIns: await daos.weights.forAnimal(puppy.id),
        placements: await daos.placements.forAnimal(puppy.id),
      ),
    );
  }

  // One read for every name the handover rows can need, rather than a lookup per
  // row — the same rule the animal's page follows.
  final buyers = puppies.every((LitterPuppy puppy) => puppy.placements.isEmpty)
      ? const <Buyer>[]
      : await daos.buyers.alphabetical();

  final body = <pw.Widget>[
    ...pdfMasthead(
      name: litter.name,
      kind: l10n.pdfLitterTitle,
      generatedLine: l10n.pdfGenerated(formatDayFor(localeTag, generatedAt)),
    ),
    ...pdfFacts(
      whelpingFacts(
        l10n,
        localeTag,
        damName: dam?.name ?? l10n.litterDamMissing,
        sireName: sire?.name,
        matingDate: litter.matingDate,
        whelpingDate: litter.whelpingDate,
        weaningDate: litter.weaningDate,
      ),
    ),
    ...pdfTable(l10n, l10n.pdfPuppies, <String>[
      l10n.animalName,
      l10n.animalSex,
      l10n.animalBirthDate,
      l10n.animalStatus,
      // The newest weigh-in, under the heading the ledger uses for the whole
      // history: a whelping box is weighed daily, and the page has room for one
      // number per puppy.
      l10n.recordsWeights,
    ], puppyRows(l10n, localeTag, puppies)),
    ...pdfTable(l10n, l10n.recordsVaccinations, <String>[
      l10n.animalName,
      l10n.vaccinationName,
      l10n.vaccinationGiven,
      l10n.vaccinationNextDue,
      l10n.vaccinationVet,
    ], doseRows(l10n, localeTag, puppies)),
    ...pdfTable(l10n, l10n.recordsPlacements, <String>[
      l10n.animalName,
      l10n.pdfBuyer,
      l10n.pdfPlacedOn,
      l10n.pdfPrice,
    ], handoverRows(l10n, localeTag, puppies, buyers)),
    if (litter.notes != null && litter.notes!.isNotEmpty)
      ...pdfSection(l10n.animalNotes, <pw.Widget>[pw.Text(litter.notes!)]),
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
      footer: (context) => pdfFooter(litter.name),
      build: (context) => body,
    ),
  );

  return document.save();
}
