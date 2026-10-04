/// Gestation length in days, per species, used only to show a breeder the
/// expected whelping date — never to invent a birth date.
///
/// Deliberately a short table: an unknown species returns null so the UI says
/// "no estimate" instead of applying dog arithmetic to a cat or a rabbit.
int? gestationDays(String species) => switch (species.trim().toLowerCase()) {
  'dog' => 63,
  'cat' => 65,
  _ => null,
};

/// Expected whelping date in Unix milliseconds, or null when either the mating
/// date or the species' gestation length is unknown.
int? expectedWhelpingDate({
  required String? species,
  required int? matingDate,
}) {
  if (species == null || matingDate == null) return null;
  final days = gestationDays(species);
  if (days == null) return null;
  // Calendar arithmetic on a local DateTime, not a raw millisecond addition:
  // a mating recorded across a daylight-saving change must still land on the
  // same day-of-month a breeder counts off a calendar.
  final day = DateTime.fromMillisecondsSinceEpoch(matingDate);
  return DateTime(day.year, day.month, day.day + days).millisecondsSinceEpoch;
}
