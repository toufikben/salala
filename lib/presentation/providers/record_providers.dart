import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vaccination.dart';
import '../../data/models/weight_entry.dart';
import 'app_providers.dart';

/// One animal's vaccination history, newest dose first.
///
/// Family + autoDispose rather than a controller per animal: a herd is open-ended
/// and a breeder works through it one card at a time, so keeping every animal's
/// records in memory for the whole session buys nothing.
final vaccinationsForAnimalProvider = FutureProvider.autoDispose
    .family<List<Vaccination>, String>(
      (ref, animalId) =>
          ref.read(daosProvider).vaccinations.forAnimal(animalId),
    );

/// One animal's weigh-ins, oldest first — the order a growth curve is drawn in.
final weightsForAnimalProvider = FutureProvider.autoDispose
    .family<List<WeightEntry>, String>(
      (ref, animalId) => ref.read(daosProvider).weights.forAnimal(animalId),
    );

/// Writes a dose either way and re-reads only the animal it belongs to.
Future<void> saveVaccination(WidgetRef ref, Vaccination vaccination) async {
  final daos = ref.read(daosProvider);
  if (vaccination.id.isEmpty) {
    await daos.vaccinations.create(vaccination);
  } else {
    await daos.vaccinations.update(vaccination);
  }
  ref.invalidate(vaccinationsForAnimalProvider(vaccination.animalId));
}

Future<void> deleteVaccination(WidgetRef ref, Vaccination vaccination) async {
  await ref.read(daosProvider).vaccinations.delete(vaccination.id);
  ref.invalidate(vaccinationsForAnimalProvider(vaccination.animalId));
}

Future<void> saveWeight(WidgetRef ref, WeightEntry entry) async {
  await ref.read(daosProvider).weights.create(entry);
  ref.invalidate(weightsForAnimalProvider(entry.animalId));
}

Future<void> deleteWeight(WidgetRef ref, WeightEntry entry) async {
  await ref.read(daosProvider).weights.delete(entry.id);
  ref.invalidate(weightsForAnimalProvider(entry.animalId));
}
