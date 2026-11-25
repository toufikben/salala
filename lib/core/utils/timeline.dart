/// One animal's life, newest first, as one list instead of six.
///
/// The animal's page has always had six sections — doses, screenings, visits,
/// weigh-ins, signs, pictures — and a handover at the bottom. Each of them is
/// the *place a record is written*: each carries its own add button, and each
/// shows its own rows newest first. What none of them can answer is the question
/// a buyer asks and a breeder asks herself: **what happened, in what order**. A
/// vaccination in March and a fever in April sit in two cards that never touch.
///
/// So this is a second reading of the same rows, not a seventh store. Nothing is
/// written here and nothing is copied: every event is a reference to a row some
/// other screen owns, and the sections stay exactly as they were. A breeder who
/// wants to log a dose still goes to the dose section.
///
/// Four decisions are worth naming, because each of them is a way this list
/// could lie:
///
/// * **A record with no date is not on the timeline.** A handover whose day was
///   never typed, or a sign observed on a day nobody wrote down, cannot be put in
///   order — and an app that guessed "probably this month" would be inventing the
///   one fact a timeline exists to state. Those rows stay visible in their own
///   section, which is where a breeder looks for them.
/// * **A dose is placed on the day it was given, never the day it is due.** A
///   next-due date is a plan; this list is what happened. Booking a future alarm
///   and printing it among the past would make the page a mixture of two tenses.
/// * **A whelping belongs to her dam, not to her sire.** The litter row names
///   both, but only one of them was in the room. The sire's own record keeps his
///   litters where a buyer's pack prints them.
/// * **A tie is broken by kind and then by id**, so two rows on one day always
///   come out in the same order. Without that the list would reshuffle itself
///   between two reads of the same database, and a breeder would think something
///   had changed.
library;

import '../../data/models/animal.dart';
import '../../data/models/health_test.dart';
import '../../data/models/litter.dart';
import '../../data/models/placement.dart';
import '../../data/models/photo.dart';
import '../../data/models/symptom.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/vet_visit.dart';
import '../../data/models/weight_entry.dart';

/// What kind of thing happened. The order of the values is the tie-break when
/// two events share a day, so it reads as a rough severity: a life began, a life
/// ended, then the records in the order the animal's page sections list them.
enum TimelineKind {
  born,
  died,
  whelped,
  vaccination,
  healthTest,
  visit,
  symptom,
  weight,
  photo,
  placement,
}

/// One dated thing that happened to one animal.
///
/// A sealed class rather than a kind plus a bag of nullable fields: every event
/// carries exactly the row it came from, so a widget that draws a dose cannot be
/// handed a weigh-in by mistake, and adding a kind later is a compile error in
/// every place that has to draw one.
sealed class TimelineEvent {
  const TimelineEvent();

  /// The day the thing happened, in unix milliseconds.
  int get atMs;

  TimelineKind get kind;

  /// A stable identity for this event, used only to break a tie between two
  /// events on one day. Empty is fine — the kind is compared first.
  String get ref;
}

/// The day she was born, from the field on the animal herself.
final class BornEvent extends TimelineEvent {
  const BornEvent(this.atMs);

  @override
  final int atMs;

  @override
  TimelineKind get kind => TimelineKind.born;

  @override
  String get ref => '';
}

/// The day she died. Only drawn for an animal whose status says so *and* whose
/// date was written: a `deceased` status with no date is a fact without a day,
/// and this list is a list of days.
final class DiedEvent extends TimelineEvent {
  const DiedEvent(this.atMs);

  @override
  final int atMs;

  @override
  TimelineKind get kind => TimelineKind.died;

  @override
  String get ref => '';
}

/// A whelping this animal carried.
final class WhelpedEvent extends TimelineEvent {
  const WhelpedEvent(this.litter, this.atMs);

  final Litter litter;

  @override
  final int atMs;

  @override
  TimelineKind get kind => TimelineKind.whelped;

  @override
  String get ref => litter.id;
}

final class VaccinationEvent extends TimelineEvent {
  const VaccinationEvent(this.dose);

  final Vaccination dose;

  @override
  int get atMs => dose.dateAdministered;

  @override
  TimelineKind get kind => TimelineKind.vaccination;

  @override
  String get ref => dose.id;
}

final class HealthTestEvent extends TimelineEvent {
  const HealthTestEvent(this.test);

  final HealthTest test;

  @override
  int get atMs => test.testDate;

  @override
  TimelineKind get kind => TimelineKind.healthTest;

  @override
  String get ref => test.id;
}

final class VisitEvent extends TimelineEvent {
  const VisitEvent(this.visit);

  final VetVisit visit;

  @override
  int get atMs => visit.visitDate;

  @override
  TimelineKind get kind => TimelineKind.visit;

  @override
  String get ref => visit.id;
}

final class SymptomEvent extends TimelineEvent {
  const SymptomEvent(this.symptom);

  final Symptom symptom;

  @override
  int get atMs => symptom.observedAt;

  @override
  TimelineKind get kind => TimelineKind.symptom;

  @override
  String get ref => symptom.id;
}

final class WeightEvent extends TimelineEvent {
  const WeightEvent(this.entry);

  final WeightEntry entry;

  @override
  int get atMs => entry.measuredAt;

  @override
  TimelineKind get kind => TimelineKind.weight;

  @override
  String get ref => entry.id;
}

final class PhotoEvent extends TimelineEvent {
  const PhotoEvent(this.photo);

  final Photo photo;

  /// When this app took its copy, which is the only date a picture honestly has:
  /// the camera's own day would need EXIF, and a picture forwarded through a
  /// messaging app carries none.
  @override
  int get atMs => photo.createdAt;

  @override
  TimelineKind get kind => TimelineKind.photo;

  @override
  String get ref => photo.id;
}

final class PlacementEvent extends TimelineEvent {
  const PlacementEvent(this.placement, this.atMs);

  final Placement placement;

  @override
  final int atMs;

  @override
  TimelineKind get kind => TimelineKind.placement;

  @override
  String get ref => placement.id;
}

/// Everything dated that happened to [animal], newest first.
///
/// The caller hands in every list the animal's page already reads, so this costs
/// no extra query: it is a sort of rows that were loaded to draw six sections.
/// A row whose date is null is left out rather than guessed — see the note at the
/// top of this file.
List<TimelineEvent> animalTimeline({
  required Animal animal,
  List<Vaccination> vaccinations = const <Vaccination>[],
  List<HealthTest> healthTests = const <HealthTest>[],
  List<VetVisit> visits = const <VetVisit>[],
  List<WeightEntry> weights = const <WeightEntry>[],
  List<Symptom> symptoms = const <Symptom>[],
  List<Photo> photos = const <Photo>[],
  List<Placement> placements = const <Placement>[],
  List<Litter> litters = const <Litter>[],
}) {
  final events = <TimelineEvent>[
    if (animal.birthDate != null) BornEvent(animal.birthDate!),
    if (animal.deathDate != null) DiedEvent(animal.deathDate!),
    // Her own whelpings. `damId` is the column that means "carried", and the
    // litter row is `ON DELETE CASCADE` from it, so this list and her own page
    // can never disagree about which whelpings are hers.
    for (final litter in litters)
      if (litter.damId == animal.id && litter.whelpingDate != null)
        WhelpedEvent(litter, litter.whelpingDate!),
    for (final dose in vaccinations) VaccinationEvent(dose),
    for (final test in healthTests) HealthTestEvent(test),
    for (final visit in visits) VisitEvent(visit),
    for (final symptom in symptoms) SymptomEvent(symptom),
    for (final entry in weights) WeightEvent(entry),
    for (final photo in photos) PhotoEvent(photo),
    // A handover with no day is not an event: it is a fact about the animal
    // ("she went to Fadwa") whose *when* was never typed, and it stays in the
    // handover section where it can still be corrected.
    for (final placement in placements)
      if (placement.placedDate != null)
        PlacementEvent(placement, placement.placedDate!),
  ];

  events.sort((a, b) {
    final byDay = b.atMs.compareTo(a.atMs);
    if (byDay != 0) return byDay;
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    return a.ref.compareTo(b.ref);
  });

  return List<TimelineEvent>.unmodifiable(events);
}
