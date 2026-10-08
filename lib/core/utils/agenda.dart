import 'package:equatable/equatable.dart';

import '../../data/models/animal.dart';
import '../../data/models/vaccination.dart';

/// How far ahead the herd agenda looks.
///
/// Two weeks because it is the span a breeder can act on: a dose due in March is
/// not this week's booking, and a window long enough to include it turns the
/// agenda into the calendar the app does not have.
const int agendaWindowDays = 14;

const double _dayMs = 86400000.0;

/// The instant the agenda stops looking: [nowMs] plus the window.
///
/// Lives here rather than in the provider that queries with it, so the list on
/// screen and the rows built from it can never disagree about how far ahead the
/// two weeks reach.
int agendaHorizonMs(int nowMs, {int windowDays = agendaWindowDays}) =>
    nowMs + (windowDays * _dayMs).round();

/// One thing to book: the earliest dose an animal still in the herd is waiting
/// for, with the count of days said the way the triage card says it.
class AgendaItem extends Equatable {
  const AgendaItem({
    required this.animalId,
    required this.animalName,
    required this.vaccineName,
    required this.dueMs,
    required this.days,
    required this.overdue,
  });

  final String animalId;
  final String animalName;
  final String vaccineName;
  final int dueMs;

  /// Whole days from now to [dueMs] — or since it, when [overdue]. Never zero:
  /// a dose due this instant reads as due today, not as a rounding artifact.
  final int days;
  final bool overdue;

  @override
  List<Object?> get props => <Object?>[
    animalId,
    animalName,
    vaccineName,
    dueMs,
    days,
    overdue,
  ];
}

/// The home screen's agenda rows, most urgent first.
///
/// Overdue rows come out ahead because `next_due_date` is what the list sorts
/// on: the dog whose rabies shot is three weeks late sits above the puppy due in
/// a fortnight, which is the order a missed booking is worth in.
///
/// One row per animal, not one per dose — the ledger of the animal tapped to
/// open shows every dose it has. [doses] may be any list in any order: the
/// window and the null dates are filtered here, so the caller reads whatever the
/// database hands back and this stays the single place that decides what counts.
List<AgendaItem> buildHerdAgenda({
  required List<Animal> animals,
  required List<Vaccination> doses,
  required int nowMs,
  int windowDays = agendaWindowDays,
}) {
  // An animal that has been sold, retired or lost is not waiting for a dose;
  // its records stay in the ledger and in the pack, off the to-do list.
  final inHerd = Map<String, String>.fromEntries(
    animals
        .where((animal) => animal.status == AnimalStatus.active)
        .map((animal) => MapEntry<String, String>(animal.id, animal.name)),
  );

  final horizon = agendaHorizonMs(nowMs, windowDays: windowDays);
  final earliest = <String, Vaccination>{};
  for (final dose in doses) {
    final due = dose.nextDueDate;
    if (due == null || due > horizon) continue;
    if (!inHerd.containsKey(dose.animalId)) continue;
    final already = earliest[dose.animalId]?.nextDueDate;
    if (already == null || due < already) earliest[dose.animalId] = dose;
  }

  final items = <AgendaItem>[];
  for (final entry in earliest.entries) {
    final due = entry.value.nextDueDate!;
    final overdue = due < nowMs;
    // Floor on a date already past, ceiling on one still to come, exactly as the
    // triage rules count them (triage.dart:89, :314) — a day that has partly
    // gone by is not a full day late, and a day still to come is not a day that
    // can be forgotten.
    final days = overdue
        ? ((nowMs - due) / _dayMs).floor()
        : ((due - nowMs) / _dayMs).ceil();
    items.add(
      AgendaItem(
        animalId: entry.key,
        animalName: inHerd[entry.key]!,
        vaccineName: entry.value.vaccineName,
        dueMs: due,
        days: days < 1 ? 1 : days,
        overdue: overdue,
      ),
    );
  }
  items.sort((a, b) => a.dueMs.compareTo(b.dueMs));
  return items;
}
