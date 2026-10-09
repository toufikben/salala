import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/l10n/triage_labels.dart';
import 'package:salala/core/utils/triage.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/symptom.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';

const int _day = 86400000;

/// Local noon, so a day count never sits on a midnight boundary where one
/// millisecond of calendar arithmetic would flip it.
final int _now = DateTime(2026, 10, 5, 12).millisecondsSinceEpoch;

/// Same day, no hours on it — the shape a day picker writes.
final int _todayMidnight = DateTime(2026, 10, 5).millisecondsSinceEpoch;

int _ago(int days) => _now - days * _day;

Animal _animal(
  String id, {
  int? ageDays,
  Sex sex = Sex.male,
  AnimalStatus status = AnimalStatus.active,
  bool breeding = false,
  String species = 'dog',
}) => Animal(
  id: id,
  name: id,
  species: species,
  sex: sex,
  status: status,
  birthDate: ageDays == null ? null : _ago(ageDays),
  isBreedingStock: breeding,
  createdAt: _ago(400),
  updatedAt: _ago(400),
);

Vaccination _dose({
  String name = 'Rabies',
  int? dueInDays,
  int? dueMs,
  int? givenDaysAgo = 100,
}) => Vaccination(
  id: 'v-$name-${dueInDays ?? dueMs ?? 0}',
  animalId: 'a',
  vaccineName: name,
  dateAdministered: _ago(givenDaysAgo ?? 0),
  nextDueDate: dueMs ?? (dueInDays == null ? null : _now + dueInDays * _day),
  createdAt: _ago(100),
  updatedAt: _ago(100),
);

WeightEntry _weigh(int grams, int daysAgo, {String id = 'w'}) => WeightEntry(
  id: '$id-$daysAgo',
  animalId: 'a',
  weightGrams: grams,
  measuredAt: _ago(daysAgo),
);

HealthTest _test(
  String type,
  String result, {
  int daysAgo = 30,
  int? validUntilInDays,
  int? untilMs,
}) => HealthTest(
  id: 'h-$type-$daysAgo',
  animalId: 'a',
  testType: type,
  result: result,
  testDate: _ago(daysAgo),
  validUntil:
      untilMs ??
      (validUntilInDays == null ? null : _now + validUntilInDays * _day),
  createdAt: _ago(daysAgo),
  updatedAt: _ago(daysAgo),
);

Litter _litter({
  String damId = 'a',
  String name = 'L1 2026',
  int? matedDaysAgo,
  int? whelpedDaysAgo,
}) => Litter(
  id: 'l-$name',
  name: name,
  damId: damId,
  matingDate: matedDaysAgo == null ? null : _ago(matedDaysAgo),
  whelpingDate: whelpedDaysAgo == null ? null : _ago(whelpedDaysAgo),
  createdAt: _ago(100),
  updatedAt: _ago(100),
);

Symptom _sight(
  String label, {
  SymptomSeverity severity = SymptomSeverity.mild,
  int daysAgo = 0,
  bool ongoing = true,
}) => Symptom(
  id: 's-$label-$daysAgo',
  animalId: 'a',
  label: label,
  severity: severity,
  observedAt: _ago(daysAgo),
  ongoing: ongoing,
  createdAt: _ago(daysAgo),
  updatedAt: _ago(daysAgo),
);

LedgerFacts _facts({
  Animal animal = const Animal(
    id: 'a',
    name: 'a',
    species: 'dog',
    sex: Sex.male,
    status: AnimalStatus.active,
    createdAt: 0,
    updatedAt: 0,
  ),
  List<Vaccination> doses = const <Vaccination>[],
  List<WeightEntry> weighIns = const <WeightEntry>[],
  List<HealthTest> tests = const <HealthTest>[],
  List<Symptom> symptoms = const <Symptom>[],
  List<Litter> litters = const <Litter>[],
}) => LedgerFacts(
  animal: animal,
  doses: doses,
  weighIns: weighIns,
  tests: tests,
  symptoms: symptoms,
  litters: litters,
  nowMs: _now,
);

/// The table as the release ships it, read off disk.
///
/// A copy typed into this file would let the test pass while the asset the app
/// actually loads stayed broken — the same reason the PDF test reads Amiri from
/// disk rather than substituting a smaller font.
String _rulesSource() => File('assets/triage/rules.json').readAsStringSync();

List<TriageRule> _shippedTable() => parseRules(_rulesSource());

TriageFinding? _finding(List<TriageFinding> findings, TriageRuleId id) {
  for (final finding in findings) {
    if (finding.ruleId == id) return finding;
  }
  return null;
}

void main() {
  late List<TriageRule> rules;

  setUpAll(() {
    rules = _shippedTable();
  });

  group('the rule table', () {
    test('is valid and covers every rule the engine knows', () {
      expect(
        rules.map((r) => r.id).toSet(),
        equals(TriageRuleId.values.toSet()),
      );
    });

    test('refuses a name nobody wrote a predicate for', () {
      expect(
        () => parseRules('{"rules": [{"id": "made_up", "urgency": "watch"}]}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('refuses a threshold typed under the wrong name', () {
      expect(
        () => parseRules(
          '{"rules": [{"id": "no_dose_young", "urgency": "actNow",'
          ' "params": {"maxDays": 140}}]}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('refuses a rule the engine has but the table left out', () {
      final decoded = jsonDecode(_rulesSource()) as Map<String, Object?>;
      final rows = (decoded['rules'] as List).cast<Map<String, Object?>>();
      final shortened = <Map<String, Object?>>[...rows]..removeAt(0);
      expect(
        () => parseRules(jsonEncode(<String, Object?>{'rules': shortened})),
        throwsA(isA<FormatException>()),
      );
    });

    test('refuses an urgency that is not one of the three', () {
      expect(
        () => parseRules(
          '{"rules": [{"id": "no_dose_young", "urgency": "emergency",'
          ' "params": {"maxAgeDays": 140}}]}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('refuses the same rule twice', () {
      final one =
          '{"rules": [{"id": "no_dose_young", "urgency": "actNow",'
          ' "params": {"maxAgeDays": 140}}, {"id": "no_dose_young",'
          ' "urgency": "watch", "params": {"maxAgeDays": 140}}]}';
      expect(() => parseRules(one), throwsA(isA<FormatException>()));
    });

    test('a rule switched off never fires', () {
      final off = rules
          .map(
            (r) => r.id == TriageRuleId.noDoseYoung
                ? TriageRule(
                    id: r.id,
                    urgency: r.urgency,
                    params: r.params,
                    enabled: false,
                  )
                : r,
          )
          .toList();
      final findings = evaluateTriage(
        _facts(animal: _animal('a', ageDays: 90)),
        off,
      );
      expect(_finding(findings, TriageRuleId.noDoseYoung), isNull);
    });
  });

  group('rules', () {
    test('a young animal with no dose recorded is an emergency', () {
      final findings = evaluateTriage(
        _facts(animal: _animal('a', ageDays: 90)),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.noDoseYoung);
      expect(finding, isNotNull);
      expect(finding!.urgency, TriageUrgency.actNow);
      expect(finding.days, 90);
    });

    test('one recorded dose is enough to silence it', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 90),
          doses: <Vaccination>[_dose()],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.noDoseYoung), isNull);
    });

    test('a grown animal with no dose recorded is not the same alarm', () {
      final findings = evaluateTriage(
        _facts(animal: _animal('a', ageDays: 400)),
        rules,
      );
      expect(_finding(findings, TriageRuleId.noDoseYoung), isNull);
    });

    test('an overdue dose names the vaccine and how late it is', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[_dose(name: 'Rabies', dueInDays: -20)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.doseOverdue);
      expect(finding, isNotNull);
      expect(finding!.urgency, TriageUrgency.routineVet);
      expect(finding.days, 20);
      expect(finding.subject, 'Rabies');
    });

    test('two days inside the grace period is not overdue', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[_dose(dueInDays: -2)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.doseOverdue), isNull);
    });

    test('the most overdue dose is the one reported', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[
            _dose(name: 'DHPP', dueInDays: -40),
            _dose(name: 'Rabies', dueInDays: -90),
          ],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.doseOverdue)!;
      expect(finding.subject, 'Rabies');
      expect(
        findings.where((f) => f.ruleId == TriageRuleId.doseOverdue).length,
        1,
      );
    });

    test('a dose coming up inside two weeks is a routine booking', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[_dose(name: 'Lepto', dueInDays: 10)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.doseDueSoon)!;
      expect(finding.days, 10);
      expect(finding.subject, 'Lepto');
    });

    test('a dose a month away is not worth a card', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[_dose(dueInDays: 30)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.doseDueSoon), isNull);
    });

    test('a dose due this morning is due today, not a day late', () {
      // The stored shape: a day picker writes midnight. Measured as an instant
      // this was already past at lunchtime, so the card went silent on a shot
      // the home agenda was painting red.
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[_dose(name: 'Rabies', dueMs: _todayMidnight)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.doseDueSoon)!;
      expect(finding.days, 0);
      expect(_finding(findings, TriageRuleId.doseOverdue), isNull);
    });

    test('tomorrow counts as one day from the afternoon', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 400),
          doses: <Vaccination>[
            _dose(name: 'Rabies', dueMs: _todayMidnight + _day),
          ],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.doseDueSoon)!.days, 1);
    });

    test(
      'a puppy losing weight is an emergency, an adult losing it is not',
      () {
        final puppy = evaluateTriage(
          _facts(
            animal: _animal('a', ageDays: 90),
            doses: <Vaccination>[_dose(dueInDays: 100)],
            weighIns: <WeightEntry>[_weigh(4000, 20), _weigh(3500, 5)],
          ),
          rules,
        );
        expect(
          _finding(puppy, TriageRuleId.weightLossPuppy)!.urgency,
          TriageUrgency.actNow,
        );
        expect(_finding(puppy, TriageRuleId.weightLoss), isNull);

        final adult = evaluateTriage(
          _facts(
            animal: _animal('a', ageDays: 900),
            doses: <Vaccination>[_dose(dueInDays: 100)],
            weighIns: <WeightEntry>[_weigh(40000, 20), _weigh(35000, 5)],
          ),
          rules,
        );
        expect(
          _finding(adult, TriageRuleId.weightLoss)!.urgency,
          TriageUrgency.watch,
        );
        expect(_finding(adult, TriageRuleId.weightLossPuppy), isNull);
      },
    );

    test('a gain between weigh-ins is no loss', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 90),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          weighIns: <WeightEntry>[_weigh(3500, 20), _weigh(4000, 5)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.weightLossPuppy), isNull);
    });

    test('a loss under the threshold is left alone', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 90),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          weighIns: <WeightEntry>[_weigh(4000, 20), _weigh(3900, 5)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.weightLossPuppy), isNull);
    });

    test('a puppy that stopped gaining is worth watching', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 60),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          weighIns: <WeightEntry>[_weigh(3000, 35), _weigh(3050, 5)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.noWeightGainPuppy)!;
      expect(finding.urgency, TriageUrgency.watch);
      expect(finding.days, 30);
    });

    test('weigh-ins too close together say nothing about growth', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 60),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          weighIns: <WeightEntry>[_weigh(3000, 10), _weigh(3000, 5)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.noWeightGainPuppy), isNull);
    });

    test('a test that did not come back clear is quoted, not interpreted', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          tests: <HealthTest>[_test('BAER', 'Unilateral')],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.healthTestFlagged)!;
      expect(finding.subject, 'BAER');
      expect(finding.urgency, TriageUrgency.routineVet);
    });

    test('the usual words for "nothing found" are not findings', () {
      for (final result in <String>['Clear', ' clear ', 'Normal', 'negative']) {
        final findings = evaluateTriage(
          _facts(
            animal: _animal('a', ageDays: 900),
            doses: <Vaccination>[_dose(dueInDays: 100)],
            tests: <HealthTest>[_test('HDC', result)],
          ),
          rules,
        );
        expect(
          _finding(findings, TriageRuleId.healthTestFlagged),
          isNull,
          reason: '"$result" should read as clear',
        );
      }
    });

    test('a re-test replaces the older answer', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          tests: <HealthTest>[
            _test('HDC', 'Affected', daysAgo: 400),
            _test('HDC', 'Clear', daysAgo: 10),
          ],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.healthTestFlagged), isNull);
    });

    test('an expired certificate matters for breeding stock only', () {
      final breeding = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, breeding: true),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          tests: <HealthTest>[
            _test('Brucellosis', 'Clear', validUntilInDays: -15),
          ],
        ),
        rules,
      );
      final finding = _finding(breeding, TriageRuleId.healthTestExpired)!;
      expect(finding.days, 15);
      expect(finding.subject, 'Brucellosis');

      final pet = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          tests: <HealthTest>[
            _test('Brucellosis', 'Clear', validUntilInDays: -15),
          ],
        ),
        rules,
      );
      expect(_finding(pet, TriageRuleId.healthTestExpired), isNull);
    });

    test('a certificate whose last day is today is still valid today', () {
      // `valid_until` is the last day the paper is good for, and it is stored at
      // that day's midnight. Compared as an instant, the certificate read as
      // lapsed from 00:00 of its own final day.
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, breeding: true),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          tests: <HealthTest>[
            _test('Brucellosis', 'Clear', untilMs: _todayMidnight),
          ],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.healthTestExpired), isNull);

      final yesterday = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, breeding: true),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          tests: <HealthTest>[
            _test('Brucellosis', 'Clear', untilMs: _todayMidnight - _day),
          ],
        ),
        rules,
      );
      expect(_finding(yesterday, TriageRuleId.healthTestExpired)!.days, 1);
    });

    test('a sign the breeder graded severe is an emergency on its own', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[
            _sight('Blood in stool', severity: SymptomSeverity.severe),
          ],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.severeSymptom)!;
      expect(finding.urgency, TriageUrgency.actNow);
      expect(finding.subject, 'Blood in stool');
    });

    test('a severe sign that was marked resolved stops alarming', () {
      // The row is the only thing that can silence it, which is why the ledger
      // opens the dialog on a tap instead of only offering a delete.
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[
            _sight(
              'Blood in stool',
              severity: SymptomSeverity.severe,
              daysAgo: 20,
              ongoing: false,
            ),
          ],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.severeSymptom), isNull);
      expect(_finding(findings, TriageRuleId.symptomUnresolved), isNull);
    });

    test('a severe sign is reported once, as the newest one', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[
            _sight('Shaking', severity: SymptomSeverity.severe, daysAgo: 9),
            _sight('Collapsing', severity: SymptomSeverity.severe, daysAgo: 1),
          ],
        ),
        rules,
      );
      final severe = findings
          .where((f) => f.ruleId == TriageRuleId.severeSymptom)
          .toList();
      expect(severe, hasLength(1));
      expect(severe.single.subject, 'Collapsing');
    });

    test('a mild sign today is not yet worth a line on the card', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[_sight('Scratching an ear')],
        ),
        rules,
      );
      expect(findings, isEmpty);
    });

    test('one day short of the threshold is still left alone', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[_sight('Scratching an ear', daysAgo: 1)],
        ),
        rules,
      );
      expect(findings, isEmpty);
    });

    test('a sign still open on the threshold day is worth watching', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[_sight('Loose stool', daysAgo: 2)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.symptomUnresolved)!;
      expect(finding.urgency, TriageUrgency.watch);
      expect(finding.days, 2);
      expect(finding.subject, 'Loose stool');
    });

    test('each mild and moderate sign that drags gets its own line', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[
            _sight('Loose stool', daysAgo: 2),
            _sight('Dull', severity: SymptomSeverity.moderate, daysAgo: 6),
            _sight('Scratching', daysAgo: 0),
          ],
        ),
        rules,
      );
      final open = findings
          .where((f) => f.ruleId == TriageRuleId.symptomUnresolved)
          .toList();
      expect(open, hasLength(2));
    });

    test('a severe sign never earns a second, quieter line', () {
      // The two rules split the grades: one row, one urgency. A card that said
      // "act now" and "keep watching" about the same sighting reads like an app
      // that does not know its own answer.
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[
            _sight('Seizure', severity: SymptomSeverity.severe, daysAgo: 30),
          ],
        ),
        rules,
      );
      expect(findings, hasLength(1));
      expect(findings.single.ruleId, TriageRuleId.severeSymptom);
    });

    test('a sighting dated ahead of this phone is not an overdue one', () {
      // Only a restored pack can hold one (the picker refuses a future day), and
      // a negative age must not slip past the threshold by being small.
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          symptoms: <Symptom>[
            _sight('Loose stool', daysAgo: -4),
            _sight('Dull', severity: SymptomSeverity.moderate, daysAgo: -4),
          ],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.symptomUnresolved), isNull);
    });

    test('a mated dam past her date is an emergency', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, sex: Sex.female),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          litters: <Litter>[_litter(matedDaysAgo: 68)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.whelpingOverdue)!;
      expect(finding.urgency, TriageUrgency.actNow);
      // 63 days of dog gestation, mated 68 days ago.
      expect(finding.days, 5);
      expect(finding.subject, 'L1 2026');
    });

    test('a cat is counted on cat arithmetic', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, sex: Sex.female, species: 'cat'),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          litters: <Litter>[_litter(matedDaysAgo: 68)],
        ),
        rules,
      );
      final finding = _finding(findings, TriageRuleId.whelpingOverdue)!;
      // 65 days for a cat, so the same mating is three days late, not five.
      expect(finding.days, 3);
    });

    test('a species with no known gestation gets no estimate', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal(
            'a',
            ageDays: 900,
            sex: Sex.female,
            species: 'rabbit',
          ),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          litters: <Litter>[_litter(matedDaysAgo: 200)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.whelpingOverdue), isNull);
    });

    test('a litter already whelped is not overdue', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, sex: Sex.female),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          litters: <Litter>[_litter(matedDaysAgo: 200, whelpedDaysAgo: 137)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.whelpingOverdue), isNull);
    });

    test('a sire is not late for anyone', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900),
          doses: <Vaccination>[_dose(dueInDays: 100)],
          litters: <Litter>[_litter(damId: 'someone-else', matedDaysAgo: 90)],
        ),
        rules,
      );
      expect(_finding(findings, TriageRuleId.whelpingOverdue), isNull);
    });
  });

  group('the verdict as a whole', () {
    test('an empty record produces no findings', () {
      final findings = evaluateTriage(
        _facts(animal: _animal('a', ageDays: 900)),
        rules,
      );
      expect(findings, isEmpty);
    });

    test('an animal that no longer lives here has no next step', () {
      // D40. Both halves in one test, because the interesting failure of this
      // rule is writing it as "not active" and calling the silence correct.
      final gone = <AnimalStatus>[AnimalStatus.deceased, AnimalStatus.sold];
      for (final status in gone) {
        expect(
          evaluateTriage(
            _facts(
              animal: _animal('a', ageDays: 90, status: status),
              doses: <Vaccination>[_dose(dueInDays: -50)],
            ),
            rules,
          ),
          isEmpty,
          reason:
              '$status: a booster someone else owes is not this card\'s news',
        );
      }

      expect(
        evaluateTriage(
          _facts(
            animal: _animal('a', ageDays: 90, status: AnimalStatus.retired),
            doses: <Vaccination>[_dose(dueInDays: -50)],
          ),
          rules,
        ),
        isNotEmpty,
        reason: 'retired is out of the whelping box, not out of the house',
      );
    });

    test('findings come back worst first', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 900, breeding: true),
          doses: <Vaccination>[_dose(name: 'Rabies', dueInDays: -20)],
          tests: <HealthTest>[_test('BAER', 'Affected')],
          weighIns: <WeightEntry>[_weigh(40000, 20), _weigh(30000, 5)],
        ),
        rules,
      );
      expect(findings.length, greaterThan(2));
      expect(
        findings.map((f) => f.urgency.index).toList(),
        orderedEquals(findings.map((f) => f.urgency.index).toList()..sort()),
      );
      expect(findings.first.urgency, TriageUrgency.watch);
    });
  });

  group('wording', () {
    test(
      'every rule has a sentence, in all three languages, in Latin digits',
      () async {
        final localizations = <AppLocalizations>[];
        for (final tag in <String>['en', 'ar', 'fr']) {
          localizations.add(await AppLocalizations.delegate.load(Locale(tag)));
        }

        for (final id in TriageRuleId.values) {
          final finding = TriageFinding(
            ruleId: id,
            urgency: TriageUrgency.watch,
            days: 12,
            percent: 18.5,
            subject: 'Rabies',
          );
          // Which part of the finding the sentence is allowed to read.
          final expected = switch (id) {
            TriageRuleId.weightLoss || TriageRuleId.weightLossPuppy => '19',
            TriageRuleId.healthTestFlagged ||
            TriageRuleId.severeSymptom => 'Rabies',
            _ => '12',
          };
          for (final l10n in localizations) {
            final message = triageMessage(l10n, finding);
            expect(
              message.trim(),
              isNotEmpty,
              reason: '${id.tableName} in ${l10n.localeName}',
            );
            // D21: a number in a triage sentence is a number a breeder acts on,
            // and Arabic-Indic digits would put it out of step with every other
            // digit on the screen.
            expect(
              message,
              contains(expected),
              reason: '${id.tableName} in ${l10n.localeName} lost its number',
            );
          }
        }
      },
    );

    test('the urgency words exist in every language', () async {
      for (final tag in <String>['en', 'ar', 'fr']) {
        final l10n = await AppLocalizations.delegate.load(Locale(tag));
        for (final urgency in TriageUrgency.values) {
          expect(
            triageUrgencyLabel(l10n, urgency).trim(),
            isNotEmpty,
            reason: '$urgency in $tag',
          );
        }
      }
    });
  });
}
