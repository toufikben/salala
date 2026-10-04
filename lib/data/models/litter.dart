import 'package:equatable/equatable.dart';

class Litter extends Equatable {
  const Litter({
    required this.id,
    required this.name,
    required this.damId,
    required this.createdAt,
    required this.updatedAt,
    this.sireId,
    this.matingDate,
    this.whelpingDate,
    this.weaningDate,
    this.notes,
  });

  final String id;
  final String name;
  final String damId;
  final String? sireId;

  /// Unix milliseconds of the mating the whelping date is counted from. The
  /// column is still named `matings` from schema v1; a re-mating overwrites it,
  /// which is what a breeder wants the expected date to follow.
  final int? matingDate;
  final int? whelpingDate;
  final int? weaningDate;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  Litter copyWith({
    String? name,
    String? damId,
    String? sireId,
    int? matingDate,
    int? whelpingDate,
    bool clearWhelpingDate = false,
    int? weaningDate,
    String? notes,
    int? updatedAt,
  }) {
    return Litter(
      id: id,
      name: name ?? this.name,
      damId: damId ?? this.damId,
      sireId: sireId ?? this.sireId,
      matingDate: matingDate ?? this.matingDate,
      whelpingDate: clearWhelpingDate
          ? null
          : (whelpingDate ?? this.whelpingDate),
      weaningDate: weaningDate ?? this.weaningDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Litter fromMap(Map<String, Object?> map) {
    return Litter(
      id: map['id']! as String,
      name: map['name']! as String,
      damId: map['dam_id']! as String,
      sireId: map['sire_id'] as String?,
      matingDate: map['matings'] as int?,
      whelpingDate: map['whelping_date'] as int?,
      weaningDate: map['weaning_date'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'dam_id': damId,
      'sire_id': sireId,
      'matings': matingDate,
      'whelping_date': whelpingDate,
      'weaning_date': weaningDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    damId,
    sireId,
    matingDate,
    whelpingDate,
    weaningDate,
    notes,
    createdAt,
    updatedAt,
  ];
}
