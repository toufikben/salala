import 'dart:convert';

import '../../data/models/animal.dart';
import '../../data/models/health_test.dart';
import '../../data/models/litter.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/weight_entry.dart';
import 'gestation.dart';

/// Where the shipped rule table lives inside the app bundle.
const String triageRulesAsset = 'assets/triage/rules.json';

const double _dayMs = 86400000.0;

/// The three answers this app is allowed to give. There is no fourth: a
/// deterministic table cannot say "this is X", only how fast to move.
enum TriageUrgency { actNow, watch, routineVet }

TriageUrgency _urgencyFromName(String name) => TriageUrgency.values.firstWhere(
  (u) => u.name == name,
  orElse: () => throw FormatException('Unknown urgency "$name"'),
);

/// Every rule the engine knows. An enum rather than bare strings so the table
/// cannot name a rule nobody wrote, and so the sentence for each one is checked
/// by the compiler in `triage_labels.dart` — a rule with no wording would be a
/// compile error, not a card that shows the breeder nothing.
enum TriageRuleId {
  noDoseYoung('no_dose_young'),
  doseOverdue('dose_overdue'),
  doseDueSoon('dose_due_soon'),
  weightLossPuppy('weight_loss_puppy'),
  weightLoss('weight_loss'),
  noWeightGainPuppy('no_weight_gain_puppy'),
  healthTestFlagged('health_test_flagged'),
  healthTestExpired('health_test_expired'),
  whelpingOverdue('whelping_overdue');

  const TriageRuleId(this.tableName);

  /// How this rule is spelled in `assets/triage/rules.json`.
  final String tableName;
}

TriageRuleId _ruleFromTableName(String name) => TriageRuleId.values.firstWhere(
  (id) => id.tableName == name,
  orElse: () => throw FormatException('No rule named "$name" is written'),
);

/// Everything a rule is allowed to know: the animal and what the breeder typed
/// about it. Nothing else — no lab feed, no symptom the record does not hold.
///
/// Vet visits are deliberately absent. Their reason and outcome are free text, so
/// a rule over them would be guessing at what "check again" meant three weeks
/// ago, and a wrong "act now" costs more trust than a missing one.
class LedgerFacts {
  const LedgerFacts({
    required this.animal,
    required this.doses,
    required this.weighIns,
    required this.tests,
    required this.litters,
    required this.nowMs,
  });

  final Animal animal;
  final List<Vaccination> doses;
  final List<WeightEntry> weighIns;
  final List<HealthTest> tests;

  /// Litters this animal stands on as dam or sire, because a mated dam whose
  /// whelping never got recorded is the one overdue event a ledger can see.
  final List<Litter> litters;
  final int nowMs;

  /// Whole days between a stored moment and `nowMs`; negative when that moment
  /// is still ahead.
  int daysSince(int ms) => ((nowMs - ms) / _dayMs).floor();

  /// Age in days, or -1 when no birth date was recorded. Every rule that reads
  /// an age returns nothing on -1 rather than assuming an animal is grown.
  int get ageDays =>
      animal.birthDate == null ? -1 : daysSince(animal.birthDate!);
}

/// One rule as the table states it.
class TriageRule {
  const TriageRule({
    required this.id,
    required this.urgency,
    required this.params,
    this.enabled = true,
  });

  final TriageRuleId id;
  final TriageUrgency urgency;
  final Map<String, double> params;
  final bool enabled;
}

/// A rule that fired, with the numbers its sentence reads off.
class TriageFinding {
  const TriageFinding({
    required this.ruleId,
    required this.urgency,
    this.days,
    this.percent,
    this.subject,
  });

  final TriageRuleId ruleId;
  final TriageUrgency urgency;
  final int? days;
  final double? percent;

  /// The dose, certificate or litter the finding is about, quoted from the
  /// record rather than named by the app.
  final String? subject;

  @override
  String toString() =>
      'TriageFinding(${ruleId.tableName}, $urgency, days: $days, '
      'percent: $percent, subject: $subject)';
}

/// What a predicate reports before the table's urgency is stamped on it.
class _Hit {
  const _Hit({this.days, this.percent, this.subject});

  final int? days;
  final double? percent;
  final String? subject;
}

typedef _RuleCheck = List<_Hit> Function(
  LedgerFacts facts,
  Map<String, double> params,
);

class _Spec {
  const _Spec(this.params, this.check);

  final Set<String> params;
  final _RuleCheck check;
}

const Map<TriageRuleId, _Spec> _specs = <TriageRuleId, _Spec>{
  TriageRuleId.noDoseYoung: _Spec({'maxAgeDays'}, _noDoseYoung),
  TriageRuleId.doseOverdue: _Spec({'graceDays'}, _doseOverdue),
  TriageRuleId.doseDueSoon: _Spec({'withinDays'}, _doseDueSoon),
  TriageRuleId.weightLossPuppy: _Spec({
    'minPercent',
    'puppyMaxAgeDays',
  }, _weightLossPuppy),
  TriageRuleId.weightLoss: _Spec({
    'minPercent',
    'puppyMaxAgeDays',
  }, _weightLossAdult),
  TriageRuleId.noWeightGainPuppy: _Spec({
    'minGainPercent',
    'minGapDays',
    'puppyMaxAgeDays',
  }, _noGainPuppy),
  TriageRuleId.healthTestFlagged: _Spec({}, _flaggedTest),
  TriageRuleId.healthTestExpired: _Spec({}, _expiredTest),
  TriageRuleId.whelpingOverdue: _Spec({'graceDays'}, _whelpingOverdue),
};

/// Reads the table. Strict on purpose: a threshold typed under the wrong name
/// would otherwise be ignored while the rule kept firing at a number nobody
/// meant, which is the worst kind of silent change.
List<TriageRule> parseRules(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('The rule table is not an object');
  }
  final rows = decoded['rules'];
  if (rows is! List) {
    throw const FormatException('The rule table has no "rules" list');
  }

  final rules = <TriageRule>[];
  for (final row in rows) {
    if (row is! Map<String, Object?>) {
      throw const FormatException('A rule row is not an object');
    }
    final rawId = row['id'];
    if (rawId is! String) throw const FormatException('A rule row has no id');
    final id = _ruleFromTableName(rawId);
    final spec = _specs[id]!;
    final urgency = row['urgency'];
    if (urgency is! String) {
      throw FormatException('Rule "$rawId" has no urgency');
    }
    final rawParams = row['params'] ?? const <String, Object?>{};
    if (rawParams is! Map<String, Object?>) {
      throw FormatException('Rule "$rawId" has params that are not an object');
    }
    final params = <String, double>{};
    rawParams.forEach((key, value) {
      if (value is! num) {
        throw FormatException('Param "$key" of rule "$rawId" is not a number');
      }
      params[key] = value.toDouble();
    });
    final missing = spec.params.difference(params.keys.toSet());
    if (missing.isNotEmpty) {
      throw FormatException('Rule "$rawId" is missing ${missing.join(', ')}');
    }
    final extra = params.keys.toSet().difference(spec.params);
    if (extra.isNotEmpty) {
      throw FormatException(
        'Rule "$rawId" carries unknown params ${extra.join(', ')}',
      );
    }
    rules.add(
      TriageRule(
        id: id,
        urgency: _urgencyFromName(urgency),
        params: params,
        enabled: (row['enabled'] as bool?) ?? true,
      ),
    );
  }

  final ids = rules.map((r) => r.id).toSet();
  if (ids.length != rules.length) {
    throw const FormatException('The rule table names a rule twice');
  }
  final leftOut = TriageRuleId.values.toSet().difference(ids);
  if (leftOut.isNotEmpty) {
    throw FormatException(
      'The rule table leaves out ${leftOut.map((i) => i.tableName).join(', ')}'
      ' — a predicate nobody turns on is dead code, and a rule nobody notices is '
      'a gap in the answer the screen gives.',
    );
  }
  return rules;
}

/// The verdict: every enabled rule that fires, worst urgency first.
List<TriageFinding> evaluateTriage(LedgerFacts facts, List<TriageRule> rules) {
  // A deceased animal has no next action. Said here rather than in nine
  // predicates, so "nothing applies" stays one rule.
  if (facts.animal.status == AnimalStatus.deceased) {
    return const <TriageFinding>[];
  }

  final findings = <TriageFinding>[];
  for (final rule in rules) {
    if (!rule.enabled) continue;
    for (final hit in _specs[rule.id]!.check(facts, rule.params)) {
      findings.add(
        TriageFinding(
          ruleId: rule.id,
          urgency: rule.urgency,
          days: hit.days,
          percent: hit.percent,
          subject: hit.subject,
        ),
      );
    }
  }
  return findings..sort((a, b) => a.urgency.index.compareTo(b.urgency.index));
}

List<_Hit> _noDoseYoung(LedgerFacts facts, Map<String, double> params) {
  final age = facts.ageDays;
  if (age < 0 || facts.doses.isNotEmpty) return const <_Hit>[];
  if (age >= params['maxAgeDays']!) return const <_Hit>[];
  return <_Hit>[_Hit(days: age)];
}

/// The single most overdue dose. Two overdue shots are one action: a phone call.
List<_Hit> _doseOverdue(LedgerFacts facts, Map<String, double> params) {
  final grace = params['graceDays']! * _dayMs;
  Vaccination? worst;
  for (final dose in facts.doses) {
    final due = dose.nextDueDate;
    if (due == null || due + grace > facts.nowMs) continue;
    if (worst == null || due < worst.nextDueDate!) worst = dose;
  }
  if (worst == null) return const <_Hit>[];
  return <_Hit>[
    _Hit(days: facts.daysSince(worst.nextDueDate!), subject: worst.vaccineName),
  ];
}

List<_Hit> _doseDueSoon(LedgerFacts facts, Map<String, double> params) {
  final horizon = params['withinDays']! * _dayMs;
  Vaccination? next;
  for (final dose in facts.doses) {
    final due = dose.nextDueDate;
    if (due == null || due < facts.nowMs) continue;
    if (due > facts.nowMs + horizon) continue;
    if (next == null || due < next.nextDueDate!) next = dose;
  }
  if (next == null) return const <_Hit>[];
  // Ceilings, and never below one: a dose due this instant has no day left to
  // it, and "due in 0 days" reads like a rounding artifact.
  final days = ((next.nextDueDate! - facts.nowMs) / _dayMs).ceil();
  return <_Hit>[_Hit(days: days < 1 ? 1 : days, subject: next.vaccineName)];
}

/// The last two weigh-ins, older of the pair first, or null when the record
/// holds fewer than two.
List<WeightEntry>? _lastTwo(LedgerFacts facts) {
  if (facts.weighIns.length < 2) return null;
  final sorted = <WeightEntry>[...facts.weighIns]
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  return <WeightEntry>[sorted[sorted.length - 2], sorted.last];
}

double? _lossPercent(List<WeightEntry> pair) {
  final before = pair.first.weightGrams;
  final after = pair.last.weightGrams;
  if (before <= 0 || after >= before) return null;
  return (before - after) * 100 / before;
}

bool _isPuppy(LedgerFacts facts, Map<String, double> params) {
  final age = facts.ageDays;
  return age >= 0 && age < params['puppyMaxAgeDays']!;
}

List<_Hit> _weightLossPuppy(LedgerFacts facts, Map<String, double> params) {
  if (!_isPuppy(facts, params)) return const <_Hit>[];
  final pair = _lastTwo(facts);
  if (pair == null) return const <_Hit>[];
  final loss = _lossPercent(pair);
  if (loss == null || loss < params['minPercent']!) return const <_Hit>[];
  return <_Hit>[_Hit(percent: loss)];
}

List<_Hit> _weightLossAdult(LedgerFacts facts, Map<String, double> params) {
  // An animal with no birth date is read as grown: a weight drop earns "watch",
  // and the louder "act now" is kept for the young, who dehydrate in a day.
  if (_isPuppy(facts, params)) return const <_Hit>[];
  final pair = _lastTwo(facts);
  if (pair == null) return const <_Hit>[];
  final loss = _lossPercent(pair);
  if (loss == null || loss < params['minPercent']!) return const <_Hit>[];
  return <_Hit>[_Hit(percent: loss)];
}

List<_Hit> _noGainPuppy(LedgerFacts facts, Map<String, double> params) {
  if (!_isPuppy(facts, params)) return const <_Hit>[];
  final pair = _lastTwo(facts);
  if (pair == null) return const <_Hit>[];
  // The span between the two weigh-ins, measured between their own moments
  // rather than as a difference of two day-counts from today: subtracting two
  // floors can land a whole day short of the interval it describes.
  final gap = ((pair.last.measuredAt - pair.first.measuredAt) / _dayMs).floor();
  if (gap < params['minGapDays']!) return const <_Hit>[];
  final before = pair.first.weightGrams;
  if (before <= 0) return const <_Hit>[];
  final gain = (pair.last.weightGrams - before) * 100 / before;
  if (gain >= params['minGainPercent']!) return const <_Hit>[];
  return <_Hit>[_Hit(days: gap)];
}

/// Results a breeder types for "nothing found". Anything else is quoted back to
/// them rather than interpreted: this app does not know what "Grade 2" means.
const Set<String> _clearResults = <String>{
  'clear',
  'normal',
  'negative',
  'free',
  'unaffected',
  '0',
};

/// The newest test of each type — a re-test replaces the older answer.
Map<String, HealthTest> _newestByType(List<HealthTest> tests) {
  final byType = <String, HealthTest>{};
  for (final test in tests) {
    final held = byType[test.testType];
    if (held == null || test.testDate > held.testDate) {
      byType[test.testType] = test;
    }
  }
  return byType;
}

List<_Hit> _flaggedTest(LedgerFacts facts, Map<String, double> params) {
  final hits = <_Hit>[];
  _newestByType(facts.tests).forEach((type, test) {
    if (_clearResults.contains(test.result.trim().toLowerCase())) return;
    hits.add(_Hit(subject: type));
  });
  return hits;
}

List<_Hit> _expiredTest(LedgerFacts facts, Map<String, double> params) {
  if (!facts.animal.isBreedingStock) return const <_Hit>[];
  final hits = <_Hit>[];
  _newestByType(facts.tests).forEach((type, test) {
    final until = test.validUntil;
    if (until == null || until > facts.nowMs) return;
    hits.add(_Hit(days: facts.daysSince(until), subject: type));
  });
  return hits;
}

List<_Hit> _whelpingOverdue(LedgerFacts facts, Map<String, double> params) {
  if (facts.animal.sex != Sex.female) return const <_Hit>[];
  final hits = <_Hit>[];
  for (final litter in facts.litters) {
    if (litter.whelpingDate != null || litter.damId != facts.animal.id) {
      continue;
    }
    final expected = expectedWhelpingDate(
      species: facts.animal.species,
      matingDate: litter.matingDate,
    );
    if (expected == null) continue;
    final late = facts.daysSince(expected);
    if (late < params['graceDays']!) continue;
    hits.add(_Hit(days: late, subject: litter.name));
  }
  return hits;
}
