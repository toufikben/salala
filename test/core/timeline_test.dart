import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/timeline.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/litter.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/photo.dart';
import 'package:salala/data/models/symptom.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/data/models/weight_entry.dart';

int day(int year, int month, int dayOfMonth) =>
    DateTime(year, month, dayOfMonth).millisecondsSinceEpoch;

Animal animal({
  String id = 'a1',
  String name = 'Nala',
  int? birthDate,
  int? deathDate,
  AnimalStatus status = AnimalStatus.active,
}) => Animal(
  id: id,
  name: name,
  species: 'dog',
  sex: Sex.female,
  status: status,
  birthDate: birthDate,
  deathDate: deathDate,
  createdAt: 0,
  updatedAt: 0,
);

Vaccination dose({
  String id = 'v1',
  String animalId = 'a1',
  String name = 'Rabies',
  required int given,
  int? due,
}) => Vaccination(
  id: id,
  animalId: animalId,
  vaccineName: name,
  dateAdministered: given,
  nextDueDate: due,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  group('animalTimeline', () {
    test('an animal with nothing written down has nothing to show', () {
      expect(animalTimeline(animal: animal()), isEmpty);
    });

    test('every dated record lands on the list, newest first', () {
      final events = animalTimeline(
        animal: animal(birthDate: day(2022, 3, 1)),
        vaccinations: <Vaccination>[
          dose(given: day(2026, 5, 1)),
          dose(id: 'v2', name: 'DHPP', given: day(2026, 7, 1)),
        ],
        weights: <WeightEntry>[
          WeightEntry(
            id: 'w1',
            animalId: 'a1',
            weightGrams: 21000,
            measuredAt: day(2026, 6, 1),
          ),
        ],
      );

      expect(events.map((e) => e.kind), <TimelineKind>[
        TimelineKind.vaccination,
        TimelineKind.weight,
        TimelineKind.vaccination,
        TimelineKind.born,
      ]);
      expect(events.first, isA<VaccinationEvent>());
      expect((events.first as VaccinationEvent).dose.vaccineName, 'DHPP');
    });

    test('a dose sits on the day it was given, never the day it is due', () {
      final events = animalTimeline(
        animal: animal(),
        vaccinations: <Vaccination>[
          dose(given: day(2026, 1, 10), due: day(2027, 1, 10)),
        ],
      );

      expect(events.single.atMs, day(2026, 1, 10));
    });

    test('a handover with no day is left to its own section', () {
      final events = animalTimeline(
        animal: animal(),
        placements: <Placement>[
          Placement(
            id: 'p1',
            animalId: 'a1',
            placedDate: null,
            createdAt: 0,
            updatedAt: 0,
          ),
          Placement(
            id: 'p2',
            animalId: 'a1',
            placedDate: day(2026, 8, 1),
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );

      // The undated one cannot be put in order, and guessing a day for it would
      // be the app inventing the one fact a timeline exists to state.
      expect(events, hasLength(1));
      expect((events.single as PlacementEvent).placement.id, 'p2');
    });

    test('a whelping belongs to her dam and not to her sire', () {
      final litter = Litter(
        id: 'l1',
        name: 'A litter',
        damId: 'a1',
        sireId: 'sire',
        whelpingDate: day(2026, 4, 4),
        createdAt: 0,
        updatedAt: 0,
      );

      final asDam = animalTimeline(
        animal: animal(id: 'a1'),
        litters: <Litter>[litter],
      );
      final asSire = animalTimeline(
        animal: animal(id: 'sire', name: 'Atlas'),
        litters: <Litter>[litter],
      );

      expect(asDam.single, isA<WhelpedEvent>());
      expect(asSire, isEmpty);
    });

    test('a whelping with no whelping date is not on the list', () {
      final events = animalTimeline(
        animal: animal(),
        litters: <Litter>[
          Litter(
            id: 'l1',
            name: 'A litter',
            damId: 'a1',
            matingDate: day(2026, 2, 2),
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );

      // A mating is not a whelping: the litter is still expected, and the heat
      // card is the page that says so.
      expect(events, isEmpty);
    });

    test('two records on one day come out in the same order every read', () {
      final first = animalTimeline(
        animal: animal(),
        vaccinations: <Vaccination>[
          dose(id: 'v2', name: 'DHPP', given: day(2026, 5, 1)),
          dose(id: 'v1', name: 'Rabies', given: day(2026, 5, 1)),
        ],
        symptoms: <Symptom>[
          Symptom(
            id: 's1',
            animalId: 'a1',
            label: 'Limp',
            severity: SymptomSeverity.mild,
            observedAt: day(2026, 5, 1),
            ongoing: true,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );
      final second = animalTimeline(
        animal: animal(),
        vaccinations: <Vaccination>[
          dose(id: 'v1', name: 'Rabies', given: day(2026, 5, 1)),
          dose(id: 'v2', name: 'DHPP', given: day(2026, 5, 1)),
        ],
        symptoms: <Symptom>[
          Symptom(
            id: 's1',
            animalId: 'a1',
            label: 'Limp',
            severity: SymptomSeverity.mild,
            observedAt: day(2026, 5, 1),
            ongoing: true,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );

      // The kind breaks the tie before the id does, so a dose and a sighting on
      // one day never swap places between two reads of the same ledger.
      expect(
        first.map((e) => '${e.kind.name}:${e.ref}'),
        second.map((e) => '${e.kind.name}:${e.ref}'),
      );
      expect(first.map((e) => e.kind).toSet(), hasLength(2));
      expect(first.first.kind, TimelineKind.vaccination);
      expect(first.last.kind, TimelineKind.symptom);
    });

    test('a death is a dated event only when the day was written', () {
      final dated = animalTimeline(
        animal: animal(
          deathDate: day(2026, 9, 9),
          status: AnimalStatus.deceased,
        ),
      );
      final undated = animalTimeline(
        animal: animal(status: AnimalStatus.deceased),
      );

      expect(dated.single, isA<DiedEvent>());
      expect(undated, isEmpty);
    });

    test('a picture sits on the day this app took its copy', () {
      final events = animalTimeline(
        animal: animal(),
        photos: <Photo>[
          Photo(
            id: 'ph1',
            animalId: 'a1',
            fileName: 'x.jpg',
            createdAt: day(2026, 3, 3),
          ),
        ],
      );

      expect(events.single.atMs, day(2026, 3, 3));
      expect(events.single, isA<PhotoEvent>());
    });

    test('a screening carries the day it was done, not the day it lapses', () {
      final events = animalTimeline(
        animal: animal(),
        healthTests: <HealthTest>[
          HealthTest(
            id: 't1',
            animalId: 'a1',
            testType: 'Hips',
            result: 'Clear',
            testDate: day(2025, 5, 5),
            validUntil: day(2028, 5, 5),
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );

      expect(events.single.atMs, day(2025, 5, 5));
    });

    test('a consultation is dated by the visit, not by when it was typed', () {
      final events = animalTimeline(
        animal: animal(),
        visits: <VetVisit>[
          VetVisit(
            id: 'vi1',
            animalId: 'a1',
            visitDate: day(2026, 2, 2),
            createdAt: day(2026, 2, 20),
            updatedAt: day(2026, 2, 20),
          ),
        ],
      );

      expect(events.single.atMs, day(2026, 2, 2));
    });

    test('a sighting is dated by the day it was seen', () {
      final events = animalTimeline(
        animal: animal(),
        symptoms: <Symptom>[
          Symptom(
            id: 's1',
            animalId: 'a1',
            label: 'Cough',
            severity: SymptomSeverity.severe,
            observedAt: day(2026, 1, 20),
            ongoing: false,
            createdAt: day(2026, 1, 25),
            updatedAt: day(2026, 1, 25),
          ),
        ],
      );

      expect(events.single.atMs, day(2026, 1, 20));
    });

    test('the list is a reading of rows it did not write', () {
      // Not a behaviour so much as the promise the page depends on: the events
      // hold the records themselves, so a tap opens the row that already exists
      // rather than a copy the timeline made.
      final record = dose(given: day(2026, 1, 1));
      final events = animalTimeline(
        animal: animal(),
        vaccinations: <Vaccination>[record],
      );

      expect((events.single as VaccinationEvent).dose, same(record));
    });
  });
}
