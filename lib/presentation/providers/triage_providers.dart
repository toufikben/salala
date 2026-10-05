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
final triageRulesProvider = FutureProvider.autoDispose<List<TriageRule>>(
  (ref) async => parseRules(await rootBundle.loadString(triageRulesAsset)),
);

/// One animal's verdict: the table applied to what this phone holds.
///
/// A family over the animal id, like every other record list here, and
/// `autoDispose` because a herd is open-ended.
final triageForAnimalProvider = FutureProvider.autoDispose
    .family<List<TriageFinding>, String>((ref, animalId) async {
      final daos = ref.read(daosProvider);
      final animal = await daos.animals.findById(animalId);
      if (animal == null) return const <TriageFinding>[];

      final rules = await ref.watch(triageRulesProvider.future);
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
