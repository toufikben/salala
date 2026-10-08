/// Money as this app stores and shows it: a plain number, no locale, no symbol.
///
/// `placements.price` and `vet_visits.cost` are `REAL` columns holding the amount
/// in the currency written beside it — a transfer pack has to say what was paid,
/// not what a rate says it is worth today. So no `intl` number format is involved
/// anywhere, which is also what keeps an Arabic ledger printing `2500` rather than
/// `٢٥٠٠` (D21).
library;

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
/// dirhams. They are shaved off the end, so a fee of 250.50 is spoken as `250.5`
/// — the same words a person writes on a receipt, and the reason this is one
/// function rather than a rule each screen repeats.
String formatPrice(double price) {
  final text = price.toStringAsFixed(2);
  if (!text.contains('.')) return text;
  return text.replaceAll(RegExp(r'\.?0+$'), '');
}

/// An amount with the code written beside it, for a document someone keeps.
///
/// The animal's transfer pack and the whelping record both have a price column,
/// and both have to answer the same three cases: nothing written down, an amount
/// in a currency nobody named, and the usual `2500 MAD`. An absent currency is
/// left off rather than printed as a trailing space, because a reader cannot tell
/// a missing code from a missing amount on paper.
///
/// A zero is nothing written down. The form cannot produce one (`parsePrice`
/// refuses it), but a transfer pack restored from a file can carry whatever
/// number the file had, and a page that reads `Price 0` tells the buyer the dog
/// was free when the honest sentence is that nobody recorded a price.
String formatPriceWithCurrency(
  double? amount,
  String? currency, {
  required String unknown,
}) {
  if (amount == null || amount <= 0) return unknown;
  final price = formatPrice(amount);
  if (currency == null || currency.isEmpty) return price;
  return '$price $currency';
}
