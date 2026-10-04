/// Weight display for a breeder's scale.
///
/// Grams are the stored unit (see `WeightEntry`), but a puppy that weighs 430 g
/// is never described in kilograms by anyone holding it, and a 30 kg dam is not
/// described in grams. The split is at one kilogram because that is where people
/// switch units in speech.
String formatWeight(int grams) {
  if (grams < 1000) return '$grams g';
  return '${(grams / 1000).toStringAsFixed(2)} kg';
}

/// Parses what a person types into a kilogram box into stored grams. A comma is
/// accepted because the keyboards on this market's phones print one. Returns null
/// for anything that is not a positive weight, so a form can show its own error
/// instead of writing nonsense to the database.
int? parseWeightToGrams(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0) return null;
  final grams = (value * 1000).round();
  // Below a tenth of a gram is a typing mistake, not a measurement.
  return grams < 1 ? null : grams;
}
