// Database schema v1 for Salala (breeder health + lineage records).
//
// Design notes (see ARCHITECTURE.md):
// - Single breeder per device: no `owners` table (the consumer-app idea from the
//   original spec was dropped for the breeder wedge).
// - `animals` covers both breeding stock and puppies; lineage is dam_id/sire_id.
// - `health_tests` is the paid differentiator (OFA/PENNFID/FCI-style screening).
// - Timestamps are Unix milliseconds (INTEGER) so they survive locale changes.

const int schemaVersion = 1;

const List<String> createStatements = <String>[
  '''
  CREATE TABLE animals (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT,
    sex TEXT NOT NULL DEFAULT 'unknown',
    birth_date INTEGER,
    death_date INTEGER,
    color TEXT,
    registration_no TEXT,
    registry TEXT,
    microchip_id TEXT,
    microchip_date INTEGER,
    dam_id TEXT,
    sire_id TEXT,
    litter_id TEXT,
    is_breeding_stock INTEGER NOT NULL DEFAULT 0,
    photo_path TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (dam_id) REFERENCES animals (id) ON DELETE SET NULL,
    FOREIGN KEY (sire_id) REFERENCES animals (id) ON DELETE SET NULL,
    FOREIGN KEY (litter_id) REFERENCES litters (id) ON DELETE SET NULL
  )
  ''',
  '''
  CREATE TABLE litters (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    dam_id TEXT NOT NULL,
    sire_id TEXT,
    matings INTEGER,
    whelping_date INTEGER,
    weaning_date INTEGER,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (dam_id) REFERENCES animals (id) ON DELETE CASCADE,
    FOREIGN KEY (sire_id) REFERENCES animals (id) ON DELETE SET NULL
  )
  ''',
  '''
  CREATE TABLE vaccinations (
    id TEXT PRIMARY KEY,
    animal_id TEXT NOT NULL,
    vaccine_name TEXT NOT NULL,
    manufacturer TEXT,
    batch_number TEXT,
    date_administered INTEGER NOT NULL,
    next_due_date INTEGER,
    vet_name TEXT,
    clinic_name TEXT,
    certificate_number TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE health_tests (
    id TEXT PRIMARY KEY,
    animal_id TEXT NOT NULL,
    test_type TEXT NOT NULL,
    result TEXT NOT NULL,
    testing_body TEXT,
    certificate_no TEXT,
    test_date INTEGER NOT NULL,
    valid_until INTEGER,
    verified_by TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE weight_entries (
    id TEXT PRIMARY KEY,
    animal_id TEXT NOT NULL,
    weight_grams INTEGER NOT NULL,
    measured_at INTEGER NOT NULL,
    note TEXT,
    FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE vet_visits (
    id TEXT PRIMARY KEY,
    animal_id TEXT NOT NULL,
    visit_date INTEGER NOT NULL,
    clinic_name TEXT,
    vet_name TEXT,
    reason TEXT,
    outcome TEXT,
    cost REAL,
    currency TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE buyers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    country_code TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE placements (
    id TEXT PRIMARY KEY,
    animal_id TEXT NOT NULL,
    buyer_id TEXT,
    placed_date INTEGER,
    price REAL,
    currency TEXT,
    guarantee_terms TEXT,
    contract_file_path TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE,
    FOREIGN KEY (buyer_id) REFERENCES buyers (id) ON DELETE SET NULL
  )
  ''',
  '''
  CREATE TABLE user_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  'CREATE INDEX idx_animals_litter ON animals (litter_id)',
  'CREATE INDEX idx_animals_dam ON animals (dam_id)',
  'CREATE INDEX idx_animals_species ON animals (species)',
  'CREATE INDEX idx_vaccinations_animal ON vaccinations (animal_id)',
  'CREATE INDEX idx_vaccinations_due ON vaccinations (next_due_date)',
  'CREATE INDEX idx_health_tests_animal ON health_tests (animal_id)',
  'CREATE INDEX idx_weights_animal ON weight_entries (animal_id, measured_at)',
  'CREATE INDEX idx_visits_animal ON vet_visits (animal_id, visit_date)',
  'CREATE INDEX idx_placements_animal ON placements (animal_id)',
];

/// Every table the database holds, in the order a reader thinks about the
/// ledger: an animal before its litter, a buyer before a placement.
///
/// The order is for reading, not for correctness — `animals.litter_id` and
/// `litters.dam_id` point at each other, so no order inserts without a dangling
/// reference. That circular pair is why a restore defers its foreign key checks
/// (see `data_pack.dart`) instead of trusting this list to break the cycle.
///
/// Export and import iterate this list, so a new table is one line here and
/// nothing else; the test that compares it against the `CREATE TABLE`
/// statements above is what stops a table from quietly going unexported.
const List<String> dataTables = <String>[
  'animals',
  'litters',
  'vaccinations',
  'health_tests',
  'weight_entries',
  'vet_visits',
  'buyers',
  'placements',
  'user_settings',
];
