import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/triage.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import 'app_providers.dart';
import 'record_providers.dart';

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
/// Every fact comes off a provider the ledger already keeps, not off the daos.
/// That is the point of the shape: the card is a derivation of these lists, so
/// reading them through `watch` is what makes it follow a record the breeder
/// just added. Reading them straight from the database made the verdict a
/// snapshot of the moment the page opened, and a dose saved on top of that page
/// moved the Vaccinations section while the card went on saying "nothing calls
/// for a next step" — measured on the test phone, where it took leaving Nala's
/// ledger and coming back to get "Rabies is due in 1 days" on screen. The lists
/// are invalidated by every write path in `record_providers.dart`, and the herd
/// and litter lists re-read themselves on every animal and litter edit, so
/// watching them covers a record this file has not heard of yet.
///
/// Every use of `ref` happens before the first `await`. `Ref.mounted` is
/// `identical(_element.ref, this)` (riverpod `ref.dart:112`) and a `watch`
/// through a stale `Ref` throws `UnmountedRefException` (`ref.dart:232-242`,
/// reached from `element.dart:989`), which riverpod's retry path renders as
/// *loading, retrying* rather than as an error — so a body that reaches back
/// for `ref` after the database has answered can be silently re-run and left
/// nowhere.
final triageForAnimalProvider = FutureProvider.autoDispose
    .family<List<TriageFinding>, String>((ref, animalId) async {
      final rules = ref.watch(triageRulesProvider.future);
      final herd = ref.watch(animalsProvider.future);
      final litters = ref.watch(littersProvider.future);
      final doses = ref.watch(vaccinationsForAnimalProvider(animalId).future);
      final weighIns = ref.watch(weightsForAnimalProvider(animalId).future);
      final tests = ref.watch(healthTestsForAnimalProvider(animalId).future);

      Animal? animal;
      for (final held in await herd) {
        if (held.id == animalId) animal = held;
      }
      if (animal == null) return const <TriageFinding>[];

      return evaluateTriage(
        LedgerFacts(
          animal: animal,
          doses: await doses,
          weighIns: await weighIns,
          tests: await tests,
          litters: <Litter>[
            for (final litter in await litters)
              if (litter.damId == animalId || litter.sireId == animalId) litter,
          ],
          nowMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
        await rules,
      );
    });
