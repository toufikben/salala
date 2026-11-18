import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Three `.arb` files are the only durable copy of what this app says, and a
/// missing translation in them is invisible to every other check in the
/// pipeline.
///
/// Stage 5c is why this file exists: it changed `animalDeleteBody` in English,
/// Arabic and French by hand, in three edits, and the only thing that keeps those
/// three sentences meaning the same thing is the person doing the editing. D43
/// says a delete warning has to name every store it destroys — a rule about a
/// string, which is worth nothing in one locale and silent in the other two.
///
/// The generated Dart files cannot carry that check. CI runs `flutter gen-l10n`
/// before it analyses or tests (`.github/workflows/flutter-ci.yml`), so whatever
/// is committed under `lib/core/l10n/` is overwritten in the runner first, and a
/// check against those files can never fail where it runs. Measured here on
/// 2026-10-11: with one key removed from `app_ar.arb`, gen-l10n wrote the
/// *English* string into `AppLocalizationsAr` — `String get recordsPhotos =>
/// 'Photos';` — with no marker of any kind in the file, and said
/// "1 untranslated message(s)" to stdout, which no test reads. An Arabic user
/// then gets one English word in the middle of an Arabic screen, and CI is green.
///
/// So this reads the `.arb` files, which nothing regenerates, and asks the
/// questions that only a reader of those files can answer — the last of them
/// about what one specific sentence has to say in each language.
void main() {
  const arbDir = 'lib/core/l10n';
  const template = 'en';
  const translated = <String>['ar', 'fr', 'de', 'es', 'it', 'pt', 'nl'];
  const allLocales = <String>[template, ...translated];

  /// Words that are spelled identically in another language and in English, and
  /// so are not evidence of an untranslated paste.
  ///
  /// Each set is measured off the files, not guessed: `appTitle` is the product
  /// name, `unitKg`/`unitGrams` are the SI symbols, `healthTestResultHelper` is
  /// the certificate's own English grading on purpose, and `Screening`,
  /// `Symptom`, `Status`, `Pedigree` and `Vaccinations` are simply the same word
  /// in German, Dutch, Italian and Portuguese. Anything else that reads
  /// character-for-character like the English is either a paste or a stranger
  /// homograph — and this list is where that gets decided, deliberately.
  const homographs = <String, Set<String>>{
    'fr': <String>{
      'appTitle',
      'animalNotes',
      'recordsPhotos',
      'recordsPlacements',
      'settingsCsvVaccinations',
      'csvColAnimal',
      'unitKg',
      'unitGrams',
      'weightNote',
      'visitNoReason',
      'pdfPlacement',
      // "Version" is the French word and the English one, and the placeholder
      // carries the only part that could differ.
      'aboutVersion',
      // The tree's heading is spelled "Pedigree" in French too.
      'pedigreeTitle',
      // "Photo" is the French word for the thing as well as the English one.
      'timelineKindPhoto',
    },
    'de': <String>{
      'appTitle',
      'animalName',
      'animalStatus',
      'unitKg',
      'unitGrams',
      'healthTestType',
      'healthTestResultHelper',
      'symptomName',
      'aboutVersion',
      // "Symptom" is the German word for the thing as well as the English one.
      'timelineKindSymptom',
      // "in {days}" is the German phrase and the English one, and the
      // placeholder carries the only part that could differ.
      'birthdayIn',
    },
    'es': <String>{
      'appTitle',
      'csvColAnimal',
      'csvColNo',
      'unitKg',
      'unitGrams',
      'healthTestResultHelper',
    },
    'it': <String>{
      'appTitle',
      'csvColNo',
      'unitKg',
      'unitGrams',
      'healthTestType',
      'healthTestResultHelper',
      'pdfPedigree',
      // Italian uses the English "privacy" for the concept, which is the word
      // the Garante itself prints; the alternative "riservatezza" is a word no
      // Italian app uses for this page.
      'privacyTitle',
      'settingsPrivacy',
      // "Pedigree" is the Italian word for the chart as well as the English one.
      'pedigreeTitle',
    },
    'pt': <String>{
      'appTitle',
      'csvColAnimal',
      'unitKg',
      'unitGrams',
      'healthTestResultHelper',
      'pdfPedigree',
      'pedigreeTitle',
    },
    'nl': <String>{
      'appTitle',
      'animalStatus',
      'unitKg',
      'unitGrams',
      'healthTestType',
      'healthTestResultHelper',
      'symptomState',
      // Dutch keeps "privacy" and "help" as loanwords in software; both are what
      // a Dutch settings screen says.
      'privacyTitle',
      'settingsPrivacy',
      'helpTitle',
      'settingsHelp',
    },
  };

  Map<String, dynamic> readArb(String locale) =>
      jsonDecode(File('$arbDir/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  /// `@@locale` and `@key` are metadata, not messages.
  List<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toList();

  String message(Map<String, dynamic> arb, String key) =>
      (arb[key] ?? '') as String;

  /// `{count}` and `{count, plural, …}` both name `count`; the `#` inside an ICU
  /// branch is not a placeholder.
  Set<String> placeholdersOf(String value) =>
      RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)[,}]')
          .allMatches(value)
          .map((match) => match.group(1)!)
          .toSet();

  final arb = <String, Map<String, dynamic>>{
    for (final locale in allLocales) locale: readArb(locale),
  };
  final keys = messageKeys(arb[template]!);

  test('the template has messages to check', () {
    // Every test below is a loop over this list. An empty one is green, and a
    // guard that cannot fail is not a guard.
    expect(keys, hasLength(greaterThan(200)));
  });

  test('every locale carries every message the template has, and no others', () {
    for (final locale in translated) {
      final localeKeys = messageKeys(arb[locale]!).toSet();
      expect(
        keys.where((key) => !localeKeys.contains(key)).toList(),
        isEmpty,
        reason:
            '$locale has no value for the keys listed above, so gen-l10n puts '
            'the English sentence in the $locale class and the $locale screen '
            'says one English word with no CI job noticing',
      );
      expect(
        localeKeys.where((key) => !keys.contains(key)).toList(),
        isEmpty,
        reason:
            '$locale carries the keys listed above, which the template does '
            'not have, so no screen can ask for them and gen-l10n drops them',
      );
    }
  });

  test('a translation fills the same holes the English message names', () {
    for (final key in keys) {
      final expected = placeholdersOf(message(arb[template]!, key));
      for (final locale in translated) {
        final value = message(arb[locale]!, key);
        if (value.isEmpty) continue; // the key test reports that one
        expect(
          placeholdersOf(value),
          equals(expected),
          reason:
              '$locale "$key" says "$value", which takes a different set of '
              'arguments than the English "$expected" — a placeholder dropped '
              'in translation is a number or a name that never reaches the '
              'sentence on screen',
        );
      }
    }
  });

  test('no message is empty in any locale', () {
    for (final locale in allLocales) {
      for (final key in messageKeys(arb[locale]!)) {
        expect(
          message(arb[locale]!, key).trim(),
          isNotEmpty,
          reason: '$locale ships an empty "$key"',
        );
      }
    }
  });

  test('every Arabic message is written in Arabic', () {
    final arabicScript = RegExp(r'[؀-ۿ]');
    final latin = <String>[];
    for (final key in keys) {
      if (!arabicScript.hasMatch(message(arb['ar']!, key))) latin.add(key);
    }
    expect(
      latin,
      isEmpty,
      reason:
          'these Arabic values carry no Arabic letter at all, which is what a '
          'value pasted from the template looks like: $latin',
    );
  });

  test('the delete warning names every store it destroys, in every locale', () {
    // The checks above are about keys, placeholders and scripts. None of them
    // can see what a sentence says, so a retranslation that keeps the shape of
    // `animalDeleteBody` and quietly drops the photographs half of it is an
    // Arabic screen promising a breeder that no picture of hers dies with the
    // animal — while CI stays green and the phone deletes the folder. That
    // sentence is the app's only promise about data it cannot get back (D43),
    // and it is worth more than a key count.
    //
    // The clauses below are spelled out here in three languages instead of
    // read from the `.arb` files, because a file compared to itself guards
    // nothing. Each one is a fragment of what a person actually read off the
    // Realme on 2026-10-12 at build `96eaa7c`, character for character equal
    // to its `.arb` value there — 231 characters in English, 205 in Arabic,
    // 241 in French. The contract clause was added when a handover gained one
    // (batch 14): it is the same kind of store, and the one that carries a
    // buyer's signature.
    //
    // A rewording that keeps the meaning has to edit this table too. That is
    // the cost, and it is the point: three edits in three files now become one
    // deliberate edit here plus the translations, and a silent drop stops
    // being silent.
    const mustName = <String, List<String>>{
      'en': <String>[
        'vaccinations',
        'health tests',
        'weights',
        'visits',
        'symptoms',
        'handover',
        'photographs',
        'files that hold them',
        'contract',
        'whelpings',
        'cannot be undone',
      ],
      'ar': <String>[
        'التطعيمات',
        'فحوصات الصحة',
        'الأوزان',
        'الزيارات البيطرية',
        'الأعراض',
        'سجل التسليم',
        'صورها',
        'ملفات تلك الصور',
        'العقد',
        'سجل ولادة',
        'لا يمكن التراجع',
      ],
      'fr': <String>[
        'vaccins',
        'tests de santé',
        'pesées',
        'visites',
        'symptômes',
        'cession',
        'photos',
        'fichiers qui les gardent',
        'contrat',
        'portée',
        'irréversible',
      ],
      'de': <String>[
        'Impfungen',
        'Gesundheitsuntersuchungen',
        'Gewichte',
        'Besuche',
        'Symptome',
        'Vermittlung',
        'Fotos',
        'Dateien, die diese',
        'Vertrag',
        'Würfe',
        'rückgängig',
      ],
      'es': <String>[
        'vacunas',
        'pruebas de salud',
        'pesos',
        'visitas',
        'síntomas',
        'entrega',
        'fotografías',
        'archivos que las guardan',
        'contrato',
        'camadas',
        'no se puede deshacer',
      ],
      'it': <String>[
        'vaccinazioni',
        'test sanitari',
        'pesi',
        'visite',
        'sintomi',
        'cessione',
        'fotografie',
        'file che le conservano',
        'contratto',
        'cucciolate',
        'irreversibile',
      ],
      'pt': <String>[
        'vacinas',
        'testes de saúde',
        'pesos',
        'visitas',
        'sintomas',
        'entrega',
        'fotografias',
        'ficheiros que as guardam',
        'contrato',
        'ninhadas',
        'não pode ser anulado',
      ],
      'nl': <String>[
        'inentingen',
        'gezondheidstests',
        'gewichten',
        'bezoeken',
        'symptomen',
        'plaatsing',
        "foto's",
        'bestanden die deze',
        'contract',
        'nestjes',
        'ongedaan',
      ],
    };
    for (final locale in allLocales) {
      // The warning is two sentences now: the list of stores, and — only for a
      // dam — the count of whelpings the cascade takes with a named tag. Read
      // together, because a breeder reads them together.
      final body =
          '${message(arb[locale]!, 'animalDeleteBody')}\n'
          '${message(arb[locale]!, 'animalDeleteLittersNote')}';
      final absent = <String>[];
      for (final fragment in mustName[locale]!) {
        if (!body.contains(fragment)) absent.add(fragment);
      }
      expect(
        absent,
        isEmpty,
        reason:
            '$locale "animalDeleteBody" says "$body", which never names '
            '${absent.join(', ')} — and a delete warning has to name every '
            'store the tap destroys, in the language the breeder reads it in',
      );
    }
  });

  test('a message that reads exactly like the English one is on the list', () {
    for (final locale in translated) {
      final identical = <String>[];
      for (final key in keys) {
        if (message(arb[locale]!, key) == message(arb[template]!, key)) {
          identical.add(key);
        }
      }
      final allowed = homographs[locale] ?? const <String>{};
      expect(
        identical.toSet().difference(allowed),
        isEmpty,
        reason:
            'these $locale values are the English strings, and "Notes" and "kg" '
            'are not among the ones that legitimately are: '
            '${identical.toSet().difference(allowed)}',
      );
      expect(
        allowed.difference(identical.toSet()),
        isEmpty,
        reason:
            'these $locale keys no longer read the same in both languages, so '
            'the list above is stale and should shrink: '
            '${allowed.difference(identical.toSet())}',
      );
    }
  });
}
