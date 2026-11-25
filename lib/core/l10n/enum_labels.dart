import '../../data/models/animal.dart';
import '../../data/models/symptom.dart';
import 'app_localizations.dart';

String sexLabel(AppLocalizations l10n, Sex sex) => switch (sex) {
  Sex.male => l10n.sexMale,
  Sex.female => l10n.sexFemale,
  Sex.unknown => l10n.sexUnknown,
};

/// The species is free text the breeder typed, and the form stores it lowercased
/// so "Dog" and "dog" are one species. Displaying that raw value would put a
/// lowercase word at the top of every animal page, so the first letter is
/// restored here — only the first, because "West Highland terrier" is already a
/// sentence and title-casing it would fight the breeder's own spelling.
String speciesLabel(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String statusLabel(AppLocalizations l10n, AnimalStatus status) =>
    switch (status) {
      AnimalStatus.active => l10n.statusActive,
      AnimalStatus.sold => l10n.statusSold,
      AnimalStatus.retired => l10n.statusRetired,
      AnimalStatus.deceased => l10n.statusDeceased,
    };

/// The breeder's own grade, so the words have to be as plain as the picker that
/// offers them: three chips, no numbers, nothing that reads like a lab result.
String severityLabel(AppLocalizations l10n, SymptomSeverity severity) =>
    switch (severity) {
      SymptomSeverity.mild => l10n.severityMild,
      SymptomSeverity.moderate => l10n.severityModerate,
      SymptomSeverity.severe => l10n.severitySevere,
    };
