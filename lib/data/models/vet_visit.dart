import 'package:equatable/equatable.dart';

class VetVisit extends Equatable {
  const VetVisit({
    required this.id,
    required this.animalId,
    required this.visitDate,
    required this.createdAt,
    required this.updatedAt,
    this.clinicName,
    this.vetName,
    this.reason,
    this.outcome,
    this.cost,
    this.currency,
    this.notes,
  });

  final String id;
  final String animalId;
  final int visitDate;
  final String? clinicName;
  final String? vetName;
  final String? reason;
  final String? outcome;
  final double? cost;
  final String? currency;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  VetVisit copyWith({
    String? animalId,
    int? visitDate,
    String? clinicName,
    String? vetName,
    String? reason,
    String? outcome,
    double? cost,
    bool clearCost = false,
    String? currency,
    String? notes,
    int? updatedAt,
  }) {
    return VetVisit(
      id: id,
      animalId: animalId ?? this.animalId,
      visitDate: visitDate ?? this.visitDate,
      clinicName: clinicName ?? this.clinicName,
      vetName: vetName ?? this.vetName,
      reason: reason ?? this.reason,
      outcome: outcome ?? this.outcome,
      cost: clearCost ? null : (cost ?? this.cost),
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static VetVisit fromMap(Map<String, Object?> map) {
    return VetVisit(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      visitDate: map['visit_date']! as int,
      clinicName: map['clinic_name'] as String?,
      vetName: map['vet_name'] as String?,
      reason: map['reason'] as String?,
      outcome: map['outcome'] as String?,
      cost: (map['cost'] as num?)?.toDouble(),
      currency: map['currency'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'visit_date': visitDate,
      'clinic_name': clinicName,
      'vet_name': vetName,
      'reason': reason,
      'outcome': outcome,
      'cost': cost,
      'currency': currency,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    animalId,
    visitDate,
    clinicName,
    vetName,
    reason,
    outcome,
    cost,
    currency,
    notes,
    createdAt,
    updatedAt,
  ];
}
