import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/triage.dart';
import '../../data/models/litter.dart';
import 'app_providers.dart';

/// The shipped rule table.
///
/// Read from the bundle rather than written into the engine so the thresholds
/// and the on/off switches are one file a release can retune without touching
/// the code that reads them (D25).
///
/// Widget tests replace this with the same file read off disk, because an
/// `await rootBundle` does not land anywhere inside `testWidgets` — not from a
/// provider body and not from inside `tester.runAsync` either (see D6 and
/// `test/helpers/pump_app.dart`). What that costs this provider is one line of
/// untested wiring: the path is covered by `triage_card_test.dart`, the parser
/// by `test/core/triage_test.dart`, and the read as it actually runs on a phone
/// is covered on a phone.
final triageRulesProvider = FutureProvider.autoDispose<List<TriageRule>>(
  (ref) async => parseRules(await rootBundle.loadString(triageRulesAsset)),
);

/// One animal's verdict: the table applied to what this phone holds.
///
/// A family over the animal id, like every other record list here, and
/// `autoDispose` because a herd is open-ended.
///
/// Every use of `ref` happens before the first `await`. `Ref.mounted` is
/// `identical(_element.ref, this)` (riverpod `ref.dart:112`) and a `watch`
/// through a stale `Ref` throws `UnmountedRefException` (`ref.dart:232-242`,
/// reached from `element.dart:989`), which riverpod's retry path renders as
/// *loading, retrying* rather than as an error — so a body that reaches back
/// for `ref` after the database has answered can be silently re-run and left
/// nowhere. This ordering also keeps the table in hand before any query, so the
/// one extra run of this body that the first `watch` provokes happens while
/// nothing is in flight.
///
/// That ordering was *not* what had 20 ledger screens stuck on a progress bar in
/// run `37431948933`; the asset read above was. It is recorded here as the
/// hygiene it is, not as a fix, because claiming it as the cause was wrong once
/// already and cost a CI cycle.
final triageForAnimalProvider = FutureProvider.autoDispose
    .family<List<TriageFinding>, String>((ref, animalId) async {
      final daos = ref.read(daosProvider);
      final rules = await ref.watch(triageRulesProvider.future);

      final animal = await daos.animals.findById(animalId);
      if (animal == null) return const <TriageFinding>[];

      final litters = <Litter>[
        ...await daos.litters.forDam(animal.id),
        ...await daos.litters.forSire(animal.id),
      ];

      return evaluateTriage(
        LedgerFacts(
          animal: animal,
          doses: await daos.vaccinations.forAnimal(animal.id),
          weighIns: await daos.weights.forAnimal(animal.id),
          tests: await daos.healthTests.forAnimal(animal.id),
          litters: litters,
          nowMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
        rules,
      );
    });
