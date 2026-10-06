import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/core/l10n/triage_labels.dart';
import 'package:salala/core/utils/triage.dart';

Future<AppLocalizations> _locale(String code) =>
    AppLocalizations.delegate.load(Locale(code));

void main() {
  test('English counts days in twos and ones', () async {
    final l10n = await _locale('en');
    expect(daysPhrase(l10n, 1), '1 day');
    expect(daysPhrase(l10n, 2), '2 days');
    expect(daysPhrase(l10n, 5), '5 days');
    expect(daysPhrase(l10n, 20), '20 days');
  });

  test('French agrees with one the way English does', () async {
    final l10n = await _locale('fr');
    expect(daysPhrase(l10n, 1), '1 jour');
    expect(daysPhrase(l10n, 3), '3 jours');
  });

  test(
    'Arabic uses the dual for two and the plural for three to ten',
    () async {
      final l10n = await _locale('ar');
      expect(daysPhrase(l10n, 1), '1 يومًا');
      expect(daysPhrase(l10n, 2), '2 يومين');
      expect(daysPhrase(l10n, 3), '3 أيام');
      expect(daysPhrase(l10n, 10), '10 أيام');
      expect(daysPhrase(l10n, 11), '11 يومًا');
      expect(daysPhrase(l10n, 20), '20 يومًا');
      expect(daysPhrase(l10n, 90), '90 يومًا');
    },
  );

  // D21: every one of the phrases above carries ASCII digits, in every locale.
  test('no day count is rendered through the locale number format', () async {
    for (final code in <String>['ar', 'en', 'fr']) {
      final l10n = await _locale(code);
      expect(
        daysPhrase(l10n, 7),
        contains('7'),
        reason: '$code switched a Latin digit for a local one',
      );
    }
  });

  test('a sentence carries the unit exactly once', () async {
    final en = await _locale('en');
    expect(
      triageMessage(
        en,
        const TriageFinding(
          ruleId: TriageRuleId.doseDueSoon,
          urgency: TriageUrgency.routineVet,
          days: 1,
          subject: 'Rabies',
        ),
      ),
      'Rabies is due in 1 day',
    );

    final ar = await _locale('ar');
    expect(
      triageMessage(
        ar,
        const TriageFinding(
          ruleId: TriageRuleId.doseOverdue,
          urgency: TriageUrgency.routineVet,
          days: 5,
          subject: 'Rabies',
        ),
      ),
      'Rabies كان مستحقًا منذ 5 أيام',
    );
  });

  // The symptom sentences are the first wording where the subject is free text
  // a breeder typed, so the noun agreement has to survive it.
  test('a symptom says its name once and its age in the right form', () async {
    final en = await _locale('en');
    expect(
      triageMessage(
        en,
        const TriageFinding(
          ruleId: TriageRuleId.severeSymptom,
          urgency: TriageUrgency.actNow,
          subject: 'Loose stool',
        ),
      ),
      'Loose stool was recorded as severe and is still happening',
    );
    expect(
      triageMessage(
        en,
        const TriageFinding(
          ruleId: TriageRuleId.symptomUnresolved,
          urgency: TriageUrgency.watch,
          days: 1,
          subject: 'Loose stool',
        ),
      ),
      'Loose stool was seen 1 day ago and is still happening',
    );

    final ar = await _locale('ar');
    expect(
      triageMessage(
        ar,
        const TriageFinding(
          ruleId: TriageRuleId.severeSymptom,
          urgency: TriageUrgency.actNow,
          subject: 'Loose stool',
        ),
      ),
      'Loose stool سُجِّل بدرجة شديدة وما زال مستمرًا',
    );
    expect(
      triageMessage(
        ar,
        const TriageFinding(
          ruleId: TriageRuleId.symptomUnresolved,
          urgency: TriageUrgency.watch,
          days: 2,
          subject: 'Loose stool',
        ),
      ),
      'ما زال Loose stool مستمرًا بعد 2 يومين من رصده',
    );
    expect(
      triageMessage(
        ar,
        const TriageFinding(
          ruleId: TriageRuleId.symptomUnresolved,
          urgency: TriageUrgency.watch,
          days: 6,
          subject: 'Loose stool',
        ),
      ),
      'ما زال Loose stool مستمرًا بعد 6 أيام من رصده',
    );
  });
}
