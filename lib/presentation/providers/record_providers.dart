import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/models/animal.dart';
import '../../data/models/health_test.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/vet_visit.dart';
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
///
/// The row as it is now stored comes back: an insert only gains its uuid in the
/// dao, and the caller needs that id to schedule reminders against the dose.
Future<Vaccination> saveVaccination(
  WidgetRef ref,
  Vaccination vaccination,
) async {
  final daos = ref.read(daosProvider);
  if (vaccination.id.isEmpty) {
    final created = await daos.vaccinations.create(vaccination);
    ref.invalidate(vaccinationsForAnimalProvider(created.animalId));
    return created;
  }
  await daos.vaccinations.update(vaccination);
  ref.invalidate(vaccinationsForAnimalProvider(vaccination.animalId));
  return vaccination;
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

/// Screening results, newest test first.
final healthTestsForAnimalProvider = FutureProvider.autoDispose
    .family<List<HealthTest>, String>(
      (ref, animalId) => ref.read(daosProvider).healthTests.forAnimal(animalId),
    );

/// Consultations, newest first.
final visitsForAnimalProvider = FutureProvider.autoDispose
    .family<List<VetVisit>, String>(
      (ref, animalId) => ref.read(daosProvider).vetVisits.forAnimal(animalId),
    );

Future<HealthTest> saveHealthTest(WidgetRef ref, HealthTest test) async {
  final daos = ref.read(daosProvider);
  if (test.id.isEmpty) {
    final created = await daos.healthTests.create(test);
    ref.invalidate(healthTestsForAnimalProvider(created.animalId));
    return created;
  }
  await daos.healthTests.update(test);
  ref.invalidate(healthTestsForAnimalProvider(test.animalId));
  return test;
}

Future<void> deleteHealthTest(WidgetRef ref, HealthTest test) async {
  await ref.read(daosProvider).healthTests.delete(test.id);
  ref.invalidate(healthTestsForAnimalProvider(test.animalId));
}

Future<void> saveVisit(WidgetRef ref, VetVisit visit) async {
  final daos = ref.read(daosProvider);
  if (visit.id.isEmpty) {
    await daos.vetVisits.create(visit);
  } else {
    await daos.vetVisits.update(visit);
  }
  ref.invalidate(visitsForAnimalProvider(visit.animalId));
}

Future<void> deleteVisit(WidgetRef ref, VetVisit visit) async {
  await ref.read(daosProvider).vetVisits.delete(visit.id);
  ref.invalidate(visitsForAnimalProvider(visit.animalId));
}

/// The name a reminder notification is filed under.
///
/// Read off the herd list every screen already watches, so naming a dose costs
/// no second query. `l10n.appTitle` stands in when the animal is not in that
/// list: a notification with an empty title cannot be acted on, and the app's
/// own name is the honest thing to show instead.
String reminderTitle(WidgetRef ref, AppLocalizations l10n, String animalId) {
  final animals = ref.read(animalsProvider).value ?? const <Animal>[];
  for (final animal in animals) {
    if (animal.id == animalId) return animal.name;
  }
  return l10n.appTitle;
}
