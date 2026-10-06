import 'package:sqflite/sqflite.dart';

import 'animal_dao.dart';
import 'buyer_dao.dart';
import 'health_test_dao.dart';
import 'litter_dao.dart';
import 'placement_dao.dart';
import 'symptom_dao.dart';
import 'vaccination_dao.dart';
import 'vet_visit_dao.dart';
import 'weight_dao.dart';

/// One handle to every record table, so providers never thread a dao per table.
class Daos {
  Daos(Database db)
    : animals = AnimalDao(db),
      litters = LitterDao(db),
      vaccinations = VaccinationDao(db),
      healthTests = HealthTestDao(db),
      weights = WeightDao(db),
      vetVisits = VetVisitDao(db),
      symptoms = SymptomDao(db),
      buyers = BuyerDao(db),
      placements = PlacementDao(db);

  final AnimalDao animals;
  final LitterDao litters;
  final VaccinationDao vaccinations;
  final HealthTestDao healthTests;
  final WeightDao weights;
  final VetVisitDao vetVisits;
  final SymptomDao symptoms;
  final BuyerDao buyers;
  final PlacementDao placements;
}
