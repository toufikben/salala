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
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/weight_entry.dart';

const int _day = 86400000;

/// Local noon, so a day count never sits on a midnight boundary where one
/// millisecond of calendar arithmetic would flip it.
final int _now = DateTime(2026, 10, 5, 12).millisecondsSinceEpoch;

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
  int? givenDaysAgo = 100,
}) => Vaccination(
  id: 'v-$name-${dueInDays ?? 0}',
  animalId: 'a',
  vaccineName: name,
  dateAdministered: _ago(givenDaysAgo ?? 0),
  nextDueDate: dueInDays == null ? null : _now + dueInDays * _day,
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
}) => HealthTest(
  id: 'h-$type-$daysAgo',
  animalId: 'a',
  testType: type,
  result: result,
  testDate: _ago(daysAgo),
  validUntil: validUntilInDays == null ? null : _now + validUntilInDays * _day,
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
  List<Litter> litters = const <Litter>[],
}) => LedgerFacts(
  animal: animal,
  doses: doses,
  weighIns: weighIns,
  tests: tests,
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

    test('a deceased animal has no next step, whatever its record holds', () {
      final findings = evaluateTriage(
        _facts(
          animal: _animal('a', ageDays: 90, status: AnimalStatus.deceased),
          doses: <Vaccination>[_dose(dueInDays: -50)],
        ),
        rules,
      );
      expect(findings, isEmpty);
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
            TriageRuleId.healthTestFlagged => 'Rabies',
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
