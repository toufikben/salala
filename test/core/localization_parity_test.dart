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
/// So this reads the `.arb` files, which nothing regenerates, and asks the four
/// questions that arrangement can actually get wrong.
void main() {
  const arbDir = 'lib/core/l10n';
  const template = 'en';
  const translated = <String>['ar', 'fr'];
  const allLocales = <String>[template, ...translated];

  /// French borrows these nine words unchanged, measured off the files rather
  /// than guessed, so the list is as long as the exception is and no longer.
  const frenchHomographs = <String>{
    'appTitle',
    'animalNotes',
    'recordsPhotos',
    'recordsPlacements',
    'unitKg',
    'unitGrams',
    'weightNote',
    'visitNoReason',
    'pdfPlacement',
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
    for (const locale in translated) {
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
      for (const locale in translated) {
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
    for (const locale in allLocales) {
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
    const arabicScript = RegExp(r'[؀-ۿ]');
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

  test(
    'a French message that reads exactly like the English one is on the list',
    () {
      final identical = <String>[];
      for (final key in keys) {
        if (message(arb['fr']!, key) == message(arb[template]!, key)) {
          identical.add(key);
        }
      }
      expect(
        identical.toSet().difference(frenchHomographs),
        isEmpty,
        reason:
            'these French values are the English strings, and "Notes" and "kg" '
            'are not among the nine that legitimately are: '
            '${identical.toSet().difference(frenchHomographs)}',
      );
      expect(
        frenchHomographs.difference(identical.toSet()),
        isEmpty,
        reason:
            'these keys no longer read the same in both languages, so the list '
            'above is stale and should shrink: '
            '${frenchHomographs.difference(identical.toSet())}',
      );
    },
  );
}
