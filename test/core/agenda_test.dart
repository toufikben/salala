import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/agenda.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';

const int _day = 86400000;

/// Local noon, so a day count never sits on a midnight boundary where one
/// millisecond of calendar arithmetic would flip it.
final int _now = DateTime(2026, 10, 5, 12).millisecondsSinceEpoch;

/// Same day, no hours on it — the shape a day picker writes.
final int _todayMidnight = DateTime(2026, 10, 5).millisecondsSinceEpoch;

Animal _animal(String id, {AnimalStatus status = AnimalStatus.active}) =>
    Animal(
      id: id,
      name: id,
      species: 'dog',
      sex: Sex.female,
      status: status,
      createdAt: _now - 400 * _day,
      updatedAt: _now - 400 * _day,
    );

Vaccination _dose({
  required String animalId,
  String name = 'Rabies',
  required int? dueInDays,
}) => Vaccination(
  id: '$animalId-$name',
  animalId: animalId,
  vaccineName: name,
  dateAdministered: _now - 100 * _day,
  nextDueDate: dueInDays == null ? null : _now + dueInDays * _day,
  createdAt: _now - 100 * _day,
  updatedAt: _now - 100 * _day,
);

void main() {
  test('a dose with no next date is not a booking', () {
    final items = buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[_dose(animalId: 'Nala', dueInDays: null)],
      nowMs: _now,
    );

    expect(items, isEmpty);
  });

  test('the window is two weeks and its edge is inside it', () {
    final items = buildHerdAgenda(
      animals: <Animal>[_animal('Nala'), _animal('Dana')],
      doses: <Vaccination>[
        _dose(animalId: 'Nala', name: 'Rabies', dueInDays: 14),
        _dose(animalId: 'Dana', name: 'Rabies', dueInDays: 15),
      ],
      nowMs: _now,
    );

    expect(items, hasLength(1));
    expect(items.single.animalId, 'Nala');
  });

  test('the window can be shortened by the caller', () {
    final items = buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[_dose(animalId: 'Nala', dueInDays: 10)],
      nowMs: _now,
      windowDays: 7,
    );

    expect(items, isEmpty);
  });

  test('one row per animal, and the earliest dose names it', () {
    final items = buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      // Deliberately out of order: the caller reads whatever the dao returns,
      // and this is the single place that decides which dose a row is about.
      doses: <Vaccination>[
        _dose(animalId: 'Nala', name: 'Rabies', dueInDays: 10),
        _dose(animalId: 'Nala', name: 'Distemper', dueInDays: 2),
      ],
      nowMs: _now,
    );

    expect(items, hasLength(1));
    expect(items.single.vaccineName, 'Distemper');
    expect(items.single.days, 2);
  });

  test('overdue comes first, most overdue ahead of it', () {
    final items = buildHerdAgenda(
      animals: <Animal>[_animal('A'), _animal('B'), _animal('C')],
      doses: <Vaccination>[
        _dose(animalId: 'C', name: 'Rabies', dueInDays: 3),
        _dose(animalId: 'B', name: 'Rabies', dueInDays: -2),
        _dose(animalId: 'A', name: 'Rabies', dueInDays: -8),
      ],
      nowMs: _now,
    );

    expect(items.map((item) => item.animalId), <String>['A', 'B', 'C']);
    expect(items.first.overdue, isTrue);
    expect(items.last.overdue, isFalse);
  });

  test('the agenda is for the animals still at this address', () {
    // D40: sold and deceased leave the to-do list, retired does not. The retired
    // row is the positive control as well as the assertion — without it this test
    // would pass on a filter that hid every status but `active`, which is what
    // this file used to do and what the owner decided against.
    final items = buildHerdAgenda(
      animals: <Animal>[
        _animal('Here'),
        _animal('Sold', status: AnimalStatus.sold),
        _animal('Retired', status: AnimalStatus.retired),
        _animal('Lost', status: AnimalStatus.deceased),
      ],
      doses: <Vaccination>[
        for (final id in <String>['Here', 'Sold', 'Retired', 'Lost'])
          _dose(animalId: id, dueInDays: 1),
      ],
      nowMs: _now,
    );

    expect(items, hasLength(2));
    expect(items.map((item) => item.animalId).toSet(), <String>{
      'Here',
      'Retired',
    });
  });

  test('a dose whose animal is not in the herd is dropped', () {
    // Not a hypothetical: `dueBefore` is a herd-wide query, and a row can be
    // older than the animal it names if a delete ever lands between the reads.
    final items = buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[_dose(animalId: 'Ghost', dueInDays: 1)],
      nowMs: _now,
    );

    expect(items, isEmpty);
  });

  test('days are counted by date, not by the hours left', () {
    AgendaItem only({required int dueInDays}) => buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[_dose(animalId: 'Nala', dueInDays: dueInDays)],
      nowMs: _now,
    ).single;

    expect(only(dueInDays: -3).days, 3);
    expect(only(dueInDays: -3).overdue, isTrue);
    expect(only(dueInDays: 5).days, 5);
    expect(only(dueInDays: 5).overdue, isFalse);

    // Twelve hours ahead is the next page of the calendar, so it is one day
    // away — the hours between the two instants are not what a breeder counts.
    final halfAhead = buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[
        _dose(animalId: 'Nala', dueInDays: null),
        Vaccination(
          id: 'half',
          animalId: 'Nala',
          vaccineName: 'Rabies',
          dateAdministered: _now,
          nextDueDate: _now + 12 * 3600 * 1000,
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
      nowMs: _now,
    ).single;
    expect(halfAhead.days, 1);
    expect(halfAhead.overdue, isFalse);

    // A dose due this instant falls on today, so it is due today: zero is the
    // answer, and the row has a sentence for it.
    final exactlyNow = buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[
        Vaccination(
          id: 'now',
          animalId: 'Nala',
          vaccineName: 'Rabies',
          dateAdministered: _now - _day,
          nextDueDate: _now,
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
      nowMs: _now,
    ).single;
    expect(exactlyNow.days, 0);
    expect(exactlyNow.overdue, isFalse);
  });

  test('a booster due this morning is not a day late at lunchtime', () {
    // The shape the app actually writes: `next_due_date` comes from a day picker
    // and lands at local midnight. Measured as an instant, this morning's date
    // was already 12 hours past at noon, and the home screen painted the row in
    // red as "1 day overdue" beside the animal's own card, which said nothing.
    AgendaItem atMidnight(int daysAgo) => buildHerdAgenda(
      animals: <Animal>[_animal('Nala')],
      doses: <Vaccination>[
        Vaccination(
          id: 'midnight-$daysAgo',
          animalId: 'Nala',
          vaccineName: 'Rabies',
          dateAdministered: _now - 100 * _day,
          nextDueDate: _todayMidnight - daysAgo * _day,
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
      nowMs: _now,
    ).single;

    expect(atMidnight(0).days, 0);
    expect(atMidnight(0).overdue, isFalse);
    expect(atMidnight(1).days, 1);
    expect(atMidnight(1).overdue, isTrue);
  });

  test('the horizon the query uses is the horizon the rows use', () {
    // The provider asks the database for `agendaHorizonMs`, then folds the
    // answer through `buildHerdAgenda`; if the two disagreed, a dose would be
    // read from disk and quietly dropped, or a row would depend on a dose that
    // was never read.
    expect(agendaHorizonMs(_now), _now + agendaWindowDays * _day);
    expect(agendaHorizonMs(_now, windowDays: 3), _now + 3 * _day);
  });
}
