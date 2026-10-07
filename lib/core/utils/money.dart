/// Money as this app stores and shows it: a plain number, no locale, no symbol.
///
/// `placements.price` and `vet_visits.cost` are `REAL` columns holding the amount
/// in the currency written beside it — a transfer pack has to say what was paid,
/// not what a rate says it is worth today. So no `intl` number format is involved
/// anywhere, which is also what keeps an Arabic ledger printing `2500` rather than
/// `٢٥٠٠` (D21).

/// Typed money in, a stored amount out.
///
/// A comma is accepted because the keyboards on this market's phones print one, and
/// `parseWeightToGrams` already treats it as a decimal separator. Returns null for
/// anything that is not a positive amount, so the form shows its own message
/// instead of writing nonsense into the ledger. A price of zero is a gift, not a
/// sale, and the row that reads 0 is the one that meant to read nothing.
double? parsePrice(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}

/// An amount as it is said out loud: `2500`, not `2500.00`.
///
/// Trailing zeros make a price read like a measurement, and a breeder types whole
/// dirhams. Two decimals are kept when there are any, because 250.50 is a real
/// number on a receipt.
String formatPrice(double price) {
  final text = price.toStringAsFixed(2);
  if (!text.contains('.')) return text;
  return text.replaceAll(RegExp(r'\.?0+$'), '');
}
