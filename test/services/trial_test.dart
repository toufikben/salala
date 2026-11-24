import 'package:flutter_test/flutter_test.dart';
import 'package:companion/data/db/settings_dao.dart';
import 'package:companion/services/trial.dart';

import '../helpers/test_db.dart';

void main() {
  late SettingsDao settings;
  late DateTime now;

  setUp(() async {
    settings = SettingsDao(await openTestDatabase());
    now = DateTime(2026, 5, 1, 9);
  });

  TrialService service() => TrialService(settings: settings, clock: () => now);

  test('a fresh install has the whole trial ahead of it', () async {
    final state = await service().state();
    expect(state.daysLeft, kTrialDays);
    expect(state.expired, isFalse);
  });

  test(
    'the trial counts from the first launch, not from each launch',
    () async {
      await service().state();
      now = DateTime(2026, 5, 11, 9);
      expect((await service().state()).daysLeft, kTrialDays - 10);
    },
  );

  test('the last day is still a day, and the next one is not', () async {
    await service().state();
    // Day 14 of the trial, late at night: one day left, and it is not over.
    now = DateTime(2026, 5, 15, 23, 50);
    final last = await service().state();
    expect(last.daysLeft, 1);
    expect(last.expired, isFalse);

    // The following morning: over, and it counts zero rather than a negative
    // number no screen would know how to phrase.
    now = DateTime(2026, 5, 16, 0, 1);
    final over = await service().state();
    expect(over.daysLeft, 0);
    expect(over.expired, isTrue);
  });

  test('the start day is written once and never moved', () async {
    await service().state();
    final first = await settings.readInt(SettingKeys.trialStartedAt);

    now = DateTime(2026, 5, 20, 9);
    await service().state();
    expect(await settings.readInt(SettingKeys.trialStartedAt), first);
  });

  test('a phone whose clock was set back does not get a longer trial', () async {
    await service().state();
    now = DateTime(2026, 5, 5, 9); // four days in
    expect((await service().state()).daysLeft, kTrialDays - 4);

    // Winding the calendar back before the install would make the elapsed count
    // negative, and arithmetic alone would read that as a full trial again.
    now = DateTime(2026, 4, 1, 9);
    expect((await service().state()).daysLeft, kTrialDays);
  });

  test(
    'the paid features lock once the trial is over and nothing was bought',
    () async {
      await service().state();
      now = DateTime(2027, 1, 1);
      final expired = service();
      expect((await expired.state()).expired, isTrue);
      for (final feature in ProFeature.values) {
        expect(
          await expired.unlocked(feature),
          isFalse,
          reason: '$feature stayed open after the trial expired',
        );
      }
    },
  );

  test(
    'a bought subscription keeps the paid features open after expiry',
    () async {
      await service().state();
      now = DateTime(2027, 1, 1);
      final expired = service();
      for (final feature in ProFeature.values) {
        expect(
          await expired.unlocked(feature, proOwned: true),
          isTrue,
          reason: '$feature stayed locked for a paying user',
        );
      }
    },
  );

  test(
    'the gate refuses what the expiry names, now that billing is on',
    () async {
      // The same arithmetic the app answers with today: expiry closes the paid
      // extras, ownership reopens them, and the trial covers everything.
      const gate = ProGate(billingEnabled: true, proOwned: false);
      expect(
        gate.allows(expired: false, feature: ProFeature.unlimitedPhotos),
        isTrue,
      );
      expect(
        gate.allows(expired: true, feature: ProFeature.unlimitedPhotos),
        isFalse,
      );

      const owned = ProGate(billingEnabled: true, proOwned: true);
      expect(
        owned.allows(expired: true, feature: ProFeature.unlimitedPhotos),
        isTrue,
      );
    },
  );
}
