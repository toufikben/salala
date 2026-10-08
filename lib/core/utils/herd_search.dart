/// Finding one animal in a herd of a hundred, by anything the breeder remembers.
///
/// A card list answers "what do I own?" in the order the database returns it. It
/// does not answer "which one was the one with the limping foot, microchip 984…",
/// and a scroll of that length is the reason a breeder with real numbers stops
/// trusting an offline app. This file decides what a query matches and in what
/// order; the screen only holds the typed text and shows what comes back, because
/// a search that ran its own query per keystroke would be a database read inside a
/// lazy list (D27).
///
/// Matching is done on *normalised* text, and normalisation is the whole design:
/// a phone keyboard puts a hamza where the ledger has an alef, and the digits of a
/// microchip are typed from a sticker with spaces in them.
library;

import '../../data/models/animal.dart';

/// The marks that change how a word is written but nobody types them from
/// memory: tashkeel (fathatan, dammata, kasrata, sukun, shadda, madda above,
/// hamza below), the dagger alef, and tatweel — the kashida a justified Arabic
/// line stretches with, which arrives in a name pasted from anywhere a line was
/// justified.
final RegExp _arabicMarks = RegExp(
  '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
);

/// The digits a keyboard set to Arabic numerals writes into a field the ledger
/// holds in Latin ones.
///
/// The app prints Latin digits everywhere by its own rule (D21), but a rule
/// about what *this* app paints is not a rule about what the keys next to it
/// produce: a phone configured for Arabic-Indic numerals offers `٠١٢` on the
/// number row, and a breeder reading a certificate aloud types straight from
/// what they see. Without this fold, `٢٥٠` is a letter-and-digit string that
/// matches nothing, and the search answers "no result" about a dog that is
/// standing in the ledger.
final RegExp _otherDigits = RegExp('[\u0660-\u0669\u06F0-\u06F9]');

String _foldDigit(Match match) {
  final int code = match[0]!.codeUnitAt(0);
  final int zero = code >= 0x06F0 ? 0x06F0 : 0x0660;
  return String.fromCharCode(0x30 + code - zero);
}

/// The letters an Arabic keyboard offers in more than one shape, folded to the
/// one shape a breeder searches with.
///
/// The last two are the same sound written by a different layout, and a ledger
/// can hold either: `ى` is what the Arabic keyboard offers where `ي` was already
/// typed, and `ی` arrives from the Persian layout a name can reach the phone on.
const Map<String, String> _arabicForms = <String, String>{
  '\u0622': '\u0627', // آ → ا
  '\u0623': '\u0627', // أ → ا
  '\u0625': '\u0627', // إ → ا
  '\u0624': '\u0648', // ؤ → و
  '\u0626': '\u064A', // ئ → ي
  '\u0629': '\u0647', // ة → ه
  '\u0649': '\u064A', // ى → ي
  '\u06CC': '\u064A', // ی → ي
};

/// Anything that is neither a letter nor a digit, for the fields that are read off
/// a sticker: registration numbers and microchips are typed with spaces and dashes
/// that the paper itself does not agree about.
final RegExp _notLetterDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// The accented forms a French-speaking breeder's keyboard offers, folded to the
/// letters a search is typed with. Deleting them instead would turn "Zoé" into
/// "zo", so a query for "zoe" would miss the animal the ledger already had.
const Map<String, String> _latinForms = <String, String>{
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'œ': 'oe',
  'ç': 'c',
  'ñ': 'n',
};

/// Lower-case, marks and letter-shapes folded, punctuation gone.
///
/// Idempotent: normalising twice changes nothing after the first pass, which is
/// what makes a query and a stored field comparable at all. It is called once
/// per field per keystroke rather than cached per animal, and that is the
/// honest cost of keeping this file free of state — a herd of a few hundred
/// short strings is cheaper than a cache that has to be invalidated every time
/// a card is edited.
String normalizeForSearch(String text) {
  var out = text
      .toLowerCase()
      .replaceAll(_arabicMarks, '')
      .replaceAllMapped(_otherDigits, _foldDigit);
  for (final MapEntry<String, String> fold in _arabicForms.entries) {
    out = out.replaceAll(fold.key, fold.value);
  }
  for (final MapEntry<String, String> fold in _latinForms.entries) {
    out = out.replaceAll(fold.key, fold.value);
  }
  return out.replaceAll(_notLetterDigit, '');
}

/// Whether [rawQuery] asks for anything at all.
///
/// The two are not the same question: a keyboard that auto-inserts a space, or
/// a dash typed ahead of a number nobody stored with one, normalises to nothing
/// and matches every animal. A screen that hid the herd's agenda on
/// `rawQuery.isNotEmpty` would then be quietly dropping a block above a list it
/// had not filtered — so both halves of the screen ask this instead.
bool queryFilters(String rawQuery) => normalizeForSearch(rawQuery).isNotEmpty;

/// How strong a match is: high enough to sort, and nothing more.
///
/// The ladder is the doc comment above it, and the rungs are a whole number
/// apart so that no two kinds of answer can tie: the name is what a breeder
/// types, so *any* name hit outranks *any* number hit, and a number outranks
/// what was written about the animal. A registration or microchip hit is a
/// different kind of answer — usually the one that settles which dog is on the
/// table — but a partial match on a number is also how two animals come up when
/// the query was one digit, so the exact form of it sorts above the substring.
int _score(Animal animal, String query) {
  final name = normalizeForSearch(animal.name);
  if (name == query) return 6;
  if (name.startsWith(query)) return 5;
  if (name.contains(query)) return 4;

  final registration = animal.registrationNo;
  final microchip = animal.microchipId;
  // The best of the two numbers, not the first one that answered: a dog can be
  // registered `MA-118` and chipped `118`, and returning from inside the loop
  // on the registration's partial hit would hide the fact that the chip is an
  // exact one.
  var byNumber = 0;
  for (final String field in <String>[?registration, ?microchip]) {
    final value = normalizeForSearch(field);
    if (value == query) return 3;
    if (value.contains(query)) byNumber = 2;
  }
  if (byNumber != 0) return byNumber;

  for (final String? field in <String?>[animal.breed, animal.notes]) {
    if (normalizeForSearch(field ?? '').contains(query)) return 1;
  }

  return 0;
}

/// The herd in the order a search should show it: strongest match first, and
/// within one strength the order the list already had.
///
/// An empty query returns the list untouched — the screen is the same widget
/// before and during a search, and a search that reorders nothing is a search a
/// breeder can read.
List<Animal> searchHerd(List<Animal> animals, String rawQuery) {
  final query = normalizeForSearch(rawQuery);
  if (query.isEmpty) return animals;

  final scored = <(int, int, Animal)>[];
  for (var i = 0; i < animals.length; i++) {
    final Animal animal = animals[i];
    final int score = _score(animal, query);
    if (score > 0) scored.add((score, i, animal));
  }
  // Not `List.sort`: it is not stable, and a list that rearranges two equally good
  // matches on every keystroke looks broken even when the set is right.
  scored.sort(((int, int, Animal) a, (int, int, Animal) b) {
    final int byScore = b.$1.compareTo(a.$1);
    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });
  return scored.map(((int, int, Animal) entry) => entry.$3).toList();
}
