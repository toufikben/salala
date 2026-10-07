import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/models/animal.dart';
import '../../data/models/buyer.dart';
import '../../data/models/health_test.dart';
import '../../data/models/placement.dart';
import '../../data/models/symptom.dart';
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

/// Sightings the breeder typed, newest first.
final symptomsForAnimalProvider = FutureProvider.autoDispose
    .family<List<Symptom>, String>(
      (ref, animalId) => ref.read(daosProvider).symptoms.forAnimal(animalId),
    );

Future<void> saveSymptom(WidgetRef ref, Symptom symptom) async {
  final daos = ref.read(daosProvider);
  if (symptom.id.isEmpty) {
    await daos.symptoms.create(symptom);
  } else {
    await daos.symptoms.update(symptom);
  }
  ref.invalidate(symptomsForAnimalProvider(symptom.animalId));
}

Future<void> deleteSymptom(WidgetRef ref, Symptom symptom) async {
  await ref.read(daosProvider).symptoms.delete(symptom.id);
  ref.invalidate(symptomsForAnimalProvider(symptom.animalId));
}

/// One animal's placements, most recent handover first.
///
/// A ledger can hold more than one: an animal bought back and re-homed, or a
/// row corrected by deleting it and writing it again. The transfer pack reads
/// the newest one, so the section lists them in the order the pack will print.
final placementsForAnimalProvider = FutureProvider.autoDispose
    .family<List<Placement>, String>(
      (ref, animalId) => ref.read(daosProvider).placements.forAnimal(animalId),
    );

/// Every buyer this breeder has handed an animal to, in name order.
///
/// One list rather than a lookup per placement: a contact list stays short, the
/// placement form offers it as its choices, and each ledger row has to print the
/// name beside the day it was written. Creating a buyer invalidates it, which is
/// what makes a contact typed for one animal show up for the next.
final buyersProvider = FutureProvider.autoDispose<List<Buyer>>(
  (ref) => ref.read(daosProvider).buyers.alphabetical(),
);

Future<Placement> savePlacement(WidgetRef ref, Placement placement) async {
  final daos = ref.read(daosProvider);
  if (placement.id.isEmpty) {
    final created = await daos.placements.create(placement);
    ref.invalidate(placementsForAnimalProvider(created.animalId));
    return created;
  }
  await daos.placements.update(placement);
  ref.invalidate(placementsForAnimalProvider(placement.animalId));
  return placement;
}

Future<void> deletePlacement(WidgetRef ref, Placement placement) async {
  await ref.read(daosProvider).placements.delete(placement.id);
  ref.invalidate(placementsForAnimalProvider(placement.animalId));
}

/// Writes a contact and returns it as stored, because the placement form that
/// asked for it has to select the id the dao just assigned.
///
/// There is no delete: `placements.buyer_id` is `ON DELETE SET NULL`, so removing
/// a buyer would quietly blank the buyer block of a document already handed over.
Future<Buyer> saveBuyer(WidgetRef ref, Buyer buyer) async {
  final daos = ref.read(daosProvider);
  if (buyer.id.isNotEmpty) {
    await daos.buyers.update(buyer);
    ref.invalidate(buyersProvider);
    return buyer;
  }
  final created = await daos.buyers.create(buyer);
  ref.invalidate(buyersProvider);
  return created;
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
