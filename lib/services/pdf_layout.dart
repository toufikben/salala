/// The page furniture every Salala document shares.
///
/// These came out of `animal_pdf.dart` when the whelping record needed the same
/// tables. A document is the one thing a buyer keeps, so two of them disagreeing
/// about what a heading looks like — or, worse, about whether an empty section
/// prints a sentence or a blank — is a defect someone discovers on paper.
///
/// The rows themselves are worked out beside each document, not here: a PDF draws
/// letters through the embedded font's glyph ids, so a test over the bytes cannot
/// read a line back. Text kept apart from the page is text CI can check.
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/l10n/app_localizations.dart';

/// The face every document embeds, declared in `pubspec.yaml` as an asset.
///
/// Named here because the caller only has to load it: `pdf` draws a glyph the
/// chosen font lacks as an empty box rather than raising, so a document built
/// without this file is silently unreadable in Arabic (D24).
const String pdfFontAsset = 'assets/fonts/Amiri-Regular.ttf';

/// The name the page is about, what kind of page it is, and the day it was made.
List<pw.Widget> pdfMasthead({
  required String name,
  required String kind,
  required String generatedLine,
}) => <pw.Widget>[
  pw.Text(
    name,
    style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
  ),
  pw.Text(
    kind,
    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
  ),
  pw.Text(
    generatedLine,
    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
  ),
  pw.SizedBox(height: 10),
];

/// Records grouped under a heading, with the heading's own spacing.
List<pw.Widget> pdfSection(String title, List<pw.Widget> body) => <pw.Widget>[
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
List<pw.Widget> pdfTable(
  AppLocalizations l10n,
  String title,
  List<String> headings,
  List<List<String>> rows, {
  List<pw.Widget> trailing = const <pw.Widget>[],
}) => pdfSection(title, <pw.Widget>[
  if (rows.isEmpty)
    pw.Text(l10n.recordsEmpty)
  else
    pw.Table(
      defaultColumnWidth: const pw.FlexColumnWidth(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: <pw.TableRow>[
        pdfRow(headings, strong: true),
        for (final List<String> row in rows) pdfRow(row),
      ],
    ),
  ...trailing,
]);

/// Label and value in two columns, for the facts that are not a history.
pw.Widget pdfFacts(List<(String, String)> facts) => pw.Table(
  defaultColumnWidth: const pw.FlexColumnWidth(2),
  columnWidths: const <int, pw.TableColumnWidth>{0: pw.FlexColumnWidth(1)},
  children: <pw.TableRow>[
    for (final (label, value) in facts) pdfRow(<String>[label, value]),
  ],
);

pw.TableRow pdfRow(List<String> cells, {bool strong = false}) => pw.TableRow(
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

/// The name repeated at the foot of every page, because a document that runs to
/// four pages gets separated from its own cover in a stack of paper.
pw.Widget pdfFooter(String name) => pw.Align(
  alignment: pw.Alignment.bottomRight,
  child: pw.Text(
    name,
    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
  ),
);
