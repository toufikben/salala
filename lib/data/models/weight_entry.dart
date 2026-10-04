import 'package:equatable/equatable.dart';

/// Weight stored in whole grams: growing puppies weigh tens or hundreds of
/// grams, and integer grams avoid both float drift and a unit column that
/// would make charting ambiguous.
class WeightEntry extends Equatable {
  const WeightEntry({
    required this.id,
    required this.animalId,
    required this.weightGrams,
    required this.measuredAt,
    this.note,
  });

  final String id;
  final String animalId;
  final int weightGrams;
  final int measuredAt;
  final String? note;

  double get weightKg => weightGrams / 1000.0;

  WeightEntry copyWith({
    String? animalId,
    int? weightGrams,
    int? measuredAt,
    String? note,
  }) {
    return WeightEntry(
      id: id,
      animalId: animalId ?? this.animalId,
      weightGrams: weightGrams ?? this.weightGrams,
      measuredAt: measuredAt ?? this.measuredAt,
      note: note ?? this.note,
    );
  }

  static WeightEntry fromMap(Map<String, Object?> map) {
    return WeightEntry(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      weightGrams: map['weight_grams']! as int,
      measuredAt: map['measured_at']! as int,
      note: map['note'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'weight_grams': weightGrams,
      'measured_at': measuredAt,
      'note': note,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    animalId,
    weightGrams,
    measuredAt,
    note,
  ];
}
