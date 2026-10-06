import '../../data/models/animal.dart';
import '../../data/models/symptom.dart';
import 'app_localizations.dart';

String sexLabel(AppLocalizations l10n, Sex sex) => switch (sex) {
  Sex.male => l10n.sexMale,
  Sex.female => l10n.sexFemale,
  Sex.unknown => l10n.sexUnknown,
};

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
