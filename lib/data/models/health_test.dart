import 'package:equatable/equatable.dart';

/// Genetic / orthopaedic screening a breeder must disclose to buyers
/// (OFA hips, PENNFID, BAER, echocardiography, ...). `testType` is free-form
/// because the recognised panel changes per breed and per registry.
class HealthTest extends Equatable {
  const HealthTest({
    required this.id,
    required this.animalId,
    required this.testType,
    required this.result,
    required this.testDate,
    required this.createdAt,
    required this.updatedAt,
    this.testingBody,
    this.certificateNo,
    this.validUntil,
    this.verifiedBy,
    this.notes,
  });

  final String id;
  final String animalId;
  final String testType;
  final String result;
  final String? testingBody;
  final String? certificateNo;
  final int testDate;
  final int? validUntil;
  final String? verifiedBy;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  bool isExpired(int nowMs) {
    final until = validUntil;
    return until != null && until < nowMs;
  }

  HealthTest copyWith({
    String? animalId,
    String? testType,
    String? result,
    String? testingBody,
    String? certificateNo,
    int? testDate,
    int? validUntil,
    bool clearValidUntil = false,
    String? verifiedBy,
    String? notes,
    int? updatedAt,
  }) {
    return HealthTest(
      id: id,
      animalId: animalId ?? this.animalId,
      testType: testType ?? this.testType,
      result: result ?? this.result,
      testingBody: testingBody ?? this.testingBody,
      certificateNo: certificateNo ?? this.certificateNo,
      testDate: testDate ?? this.testDate,
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static HealthTest fromMap(Map<String, Object?> map) {
    return HealthTest(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      testType: map['test_type']! as String,
      result: map['result']! as String,
      testingBody: map['testing_body'] as String?,
      certificateNo: map['certificate_no'] as String?,
      testDate: map['test_date']! as int,
      validUntil: map['valid_until'] as int?,
      verifiedBy: map['verified_by'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'test_type': testType,
      'result': result,
      'testing_body': testingBody,
      'certificate_no': certificateNo,
      'test_date': testDate,
      'valid_until': validUntil,
      'verified_by': verifiedBy,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    animalId,
    testType,
    result,
    testingBody,
    certificateNo,
    testDate,
    validUntil,
    verifiedBy,
    notes,
    createdAt,
    updatedAt,
  ];
}
