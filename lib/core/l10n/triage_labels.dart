import '../utils/triage.dart';
import 'app_localizations.dart';

/// The word a finding is filed under.
String triageUrgencyLabel(AppLocalizations l10n, TriageUrgency urgency) =>
    switch (urgency) {
      TriageUrgency.actNow => l10n.triageActNow,
      TriageUrgency.watch => l10n.triageWatch,
      TriageUrgency.routineVet => l10n.triageRoutineVet,
    };

/// One sentence per rule, and the switch is exhaustive over `TriageRuleId`: a
/// rule added to the engine without wording here does not compile.
///
/// Every number is written as plain ASCII digits (D21) rather than passed to
/// `intl` as an `int`, because the Arabic locale would otherwise render "٥ أيام"
/// beside the Latin digits the rest of the app shows.
String triageMessage(
  AppLocalizations l10n,
  TriageFinding finding,
) => switch (finding.ruleId) {
  TriageRuleId.noDoseYoung => l10n.triageNoDoseYoung(_days(finding)),
  TriageRuleId.doseOverdue => l10n.triageDoseOverdue(
    _subject(finding),
    _days(finding),
  ),
  TriageRuleId.doseDueSoon => l10n.triageDoseDueSoon(
    _subject(finding),
    _days(finding),
  ),
  TriageRuleId.weightLossPuppy => l10n.triageWeightLossPuppy(_percent(finding)),
  TriageRuleId.weightLoss => l10n.triageWeightLoss(_percent(finding)),
  TriageRuleId.noWeightGainPuppy => l10n.triageNoGainPuppy(_days(finding)),
  TriageRuleId.healthTestFlagged => l10n.triageTestFlagged(_subject(finding)),
  TriageRuleId.healthTestExpired => l10n.triageTestExpired(
    _subject(finding),
    _days(finding),
  ),
  TriageRuleId.whelpingOverdue => l10n.triageWhelpingOverdue(
    _subject(finding),
    _days(finding),
  ),
};

String _days(TriageFinding finding) => '${finding.days ?? 0}';

String _percent(TriageFinding finding) => '${(finding.percent ?? 0).round()}';

/// The dose, certificate or litter the rule fired on. The record supplies it, so
/// an absent subject means the predicate forgot to quote one — which
/// `triage_test.dart` checks rule by rule.
String _subject(TriageFinding finding) => finding.subject ?? '';
