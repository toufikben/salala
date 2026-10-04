import 'package:sqflite/sqflite.dart';

import 'animal_dao.dart';
import 'buyer_dao.dart';
import 'health_test_dao.dart';
import 'litter_dao.dart';
import 'placement_dao.dart';
import 'vaccination_dao.dart';
import 'vet_visit_dao.dart';
import 'weight_dao.dart';

/// One handle to every table, so providers never thread eight dao arguments.
class Daos {
  Daos(Database db)
    : animals = AnimalDao(db),
      litters = LitterDao(db),
      vaccinations = VaccinationDao(db),
      healthTests = HealthTestDao(db),
      weights = WeightDao(db),
      vetVisits = VetVisitDao(db),
      buyers = BuyerDao(db),
      placements = PlacementDao(db);

  final AnimalDao animals;
  final LitterDao litters;
  final VaccinationDao vaccinations;
  final HealthTestDao healthTests;
  final WeightDao weights;
  final VetVisitDao vetVisits;
  final BuyerDao buyers;
  final PlacementDao placements;
}
