/// Text a breeder typed, or nothing at all.
///
/// The forms used to store `_note.text.trim()`, which is `''` for an empty box
/// and not `null`. The difference is not cosmetic: `animal.breed ?? label` never
/// fired, because `''` is a value; "is this field filled in?" comparisons were
/// true for a field nobody filled; the restored pack carried empty strings where
/// the original ledger had NULL; and a printed document printed a blank where it
/// should have printed "not recorded".
///
/// One helper, applied at every form boundary, so the ledger has a single
/// representation of "not written down".
library;

/// [value] trimmed, or `null` when it is absent or only whitespace.
String? blankToNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// [value] trimmed, or the empty string when it is absent.
///
/// For the required columns — a name, a species, a vaccine — where NULL is not
/// an option the schema allows and the form has already refused the save.
String requiredText(String? value) => value?.trim() ?? '';
