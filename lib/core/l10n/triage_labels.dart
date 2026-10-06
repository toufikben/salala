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
  TriageRuleId.noDoseYoung => l10n.triageNoDoseYoung(_days(l10n, finding)),
  TriageRuleId.doseOverdue => l10n.triageDoseOverdue(
    _subject(finding),
    _days(l10n, finding),
  ),
  TriageRuleId.doseDueSoon => l10n.triageDoseDueSoon(
    _subject(finding),
    _days(l10n, finding),
  ),
  TriageRuleId.weightLossPuppy => l10n.triageWeightLossPuppy(_percent(finding)),
  TriageRuleId.weightLoss => l10n.triageWeightLoss(_percent(finding)),
  TriageRuleId.noWeightGainPuppy => l10n.triageNoGainPuppy(
    _days(l10n, finding),
  ),
  TriageRuleId.healthTestFlagged => l10n.triageTestFlagged(_subject(finding)),
  TriageRuleId.healthTestExpired => l10n.triageTestExpired(
    _subject(finding),
    _days(l10n, finding),
  ),
  TriageRuleId.whelpingOverdue => l10n.triageWhelpingOverdue(
    _subject(finding),
    _days(l10n, finding),
  ),
};

/// A counted number of days, said the way this language says that number.
///
/// The count is still spelled as plain ASCII digits (D21), which is why the
/// form is picked here instead of by `intl`'s plural logic: `Intl.plural`
/// renders the number itself through the locale's number format, so an Arabic
/// card would show "٥ أيام" beside the "5" every other line on the screen
/// writes.
///
/// Arabic counts three ways, not two: 2 takes the dual, 3-10 take the plural,
/// and 1 and 11-99 take the singular. English and French only ever need the
/// first and the third, and both give them the same two answers.
String daysPhrase(AppLocalizations l10n, int n) {
  final count = '$n';
  if (l10n.localeName == 'ar') {
    if (n == 2) return l10n.daysDual(count);
    if (n >= 3 && n <= 10) return l10n.daysPlural(count);
    return l10n.daysSingle(count);
  }
  return n == 1 ? l10n.daysSingle(count) : l10n.daysPlural(count);
}

String _days(AppLocalizations l10n, TriageFinding finding) =>
    daysPhrase(l10n, finding.days ?? 0);

String _percent(TriageFinding finding) => '${(finding.percent ?? 0).round()}';

/// The dose, certificate or litter the rule fired on. The record supplies it, so
/// an absent subject means the predicate forgot to quote one — which
/// `triage_test.dart` checks rule by rule.
String _subject(TriageFinding finding) => finding.subject ?? '';
