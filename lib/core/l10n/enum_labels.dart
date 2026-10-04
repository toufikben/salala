import '../../data/models/animal.dart';
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
