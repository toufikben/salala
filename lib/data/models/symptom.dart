import 'package:equatable/equatable.dart';

/// How much the sight worries the breeder. Three levels, not a 1-10 scale: a
/// scale invites a number nobody can compare across animals, while "a puppy is
/// dull and won't feed" and "there is blood in the stool" are different
/// decisions about calling a vet tonight.
enum SymptomSeverity { mild, moderate, severe }

SymptomSeverity symptomSeverityFromName(String? value) => SymptomSeverity.values
    .firstWhere((e) => e.name == value, orElse: () => SymptomSeverity.mild);

/// Something the breeder *saw* on an animal, recorded as a fact with a date
/// instead of surviving only in a vet-visit note. `label` is free-form for the
/// same reason `HealthTest.testType` is: the signs worth writing down depend on
/// breed and age, and a fixed list would be a list to migrate.
class Symptom extends Equatable {
  const Symptom({
    required this.id,
    required this.animalId,
    required this.label,
    required this.severity,
    required this.observedAt,
    required this.ongoing,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final String animalId;
  final String label;
  final SymptomSeverity severity;

  /// When the sign was seen, not when the row was typed: a breeder who notes a
  /// limp the evening after it started must not push the urgency clock forward.
  final int observedAt;

  /// Still happening. A resolved sign stays on the ledger as history but stops
  /// making the card alarm.
  final bool ongoing;
  final String? note;
  final int createdAt;
  final int updatedAt;

  Symptom copyWith({
    String? animalId,
    String? label,
    SymptomSeverity? severity,
    int? observedAt,
    bool? ongoing,
    String? note,
    bool clearNote = false,
    int? updatedAt,
  }) {
    return Symptom(
      id: id,
      animalId: animalId ?? this.animalId,
      label: label ?? this.label,
      severity: severity ?? this.severity,
      observedAt: observedAt ?? this.observedAt,
      ongoing: ongoing ?? this.ongoing,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Symptom fromMap(Map<String, Object?> map) {
    return Symptom(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      label: map['label']! as String,
      severity: symptomSeverityFromName(map['severity'] as String?),
      observedAt: map['observed_at']! as int,
      ongoing: (map['ongoing'] as int? ?? 1) == 1,
      note: map['note'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'label': label,
      'severity': severity.name,
      'observed_at': observedAt,
      'ongoing': ongoing ? 1 : 0,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    animalId,
    label,
    severity,
    observedAt,
    ongoing,
    note,
    createdAt,
    updatedAt,
  ];
}
