import 'package:equatable/equatable.dart';

class Vaccination extends Equatable {
  const Vaccination({
    required this.id,
    required this.animalId,
    required this.vaccineName,
    required this.dateAdministered,
    required this.createdAt,
    required this.updatedAt,
    this.manufacturer,
    this.batchNumber,
    this.nextDueDate,
    this.vetName,
    this.clinicName,
    this.certificateNumber,
  });

  final String id;
  final String animalId;
  final String vaccineName;
  final String? manufacturer;
  final String? batchNumber;
  final int dateAdministered;
  final int? nextDueDate;
  final String? vetName;
  final String? clinicName;
  final String? certificateNumber;
  final int createdAt;
  final int updatedAt;

  bool isOverdue(int nowMs) {
    final due = nextDueDate;
    return due != null && due < nowMs;
  }

  Vaccination copyWith({
    String? animalId,
    String? vaccineName,
    String? manufacturer,
    String? batchNumber,
    int? dateAdministered,
    int? nextDueDate,
    bool clearNextDueDate = false,
    String? vetName,
    String? clinicName,
    String? certificateNumber,
    int? updatedAt,
  }) {
    return Vaccination(
      id: id,
      animalId: animalId ?? this.animalId,
      vaccineName: vaccineName ?? this.vaccineName,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      dateAdministered: dateAdministered ?? this.dateAdministered,
      nextDueDate: clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      vetName: vetName ?? this.vetName,
      clinicName: clinicName ?? this.clinicName,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Vaccination fromMap(Map<String, Object?> map) {
    return Vaccination(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      vaccineName: map['vaccine_name']! as String,
      manufacturer: map['manufacturer'] as String?,
      batchNumber: map['batch_number'] as String?,
      dateAdministered: map['date_administered']! as int,
      nextDueDate: map['next_due_date'] as int?,
      vetName: map['vet_name'] as String?,
      clinicName: map['clinic_name'] as String?,
      certificateNumber: map['certificate_number'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'vaccine_name': vaccineName,
      'manufacturer': manufacturer,
      'batch_number': batchNumber,
      'date_administered': dateAdministered,
      'next_due_date': nextDueDate,
      'vet_name': vetName,
      'clinic_name': clinicName,
      'certificate_number': certificateNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    animalId,
    vaccineName,
    manufacturer,
    batchNumber,
    dateAdministered,
    nextDueDate,
    vetName,
    clinicName,
    certificateNumber,
    createdAt,
    updatedAt,
  ];
}
