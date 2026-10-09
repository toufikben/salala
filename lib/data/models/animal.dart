import 'package:equatable/equatable.dart';

enum Sex { male, female, unknown }

enum AnimalStatus {
  active,
  sold,
  retired,
  deceased;

  /// Whether this animal is still *at the address*, which is the question that
  /// decides whether the phone may wake the breeder for it and whether the home
  /// agenda may list a dose of it (D40).
  ///
  /// `retired` counts, because the word is about the breeding plan and not about
  /// the household: a retired dam sleeps in the house and still needs her annual
  /// shot, and a reminder that stopped firing because she left the whelping box
  /// is worse than no reminder — the breeder has no reason to suspect the ledger
  /// went quiet on purpose. `sold` and `deceased` do not, because the person who
  /// owes that booking is someone else, or nobody.
  ///
  /// One getter rather than three comparisons, so the agenda, the triage card and
  /// the launch that re-books alarms cannot each guess the same question
  /// differently — which is exactly what they did before this line existed.
  bool get isAtHome =>
      this == AnimalStatus.active || this == AnimalStatus.retired;
}

Sex sexFromName(String? value) =>
    Sex.values.firstWhere((e) => e.name == value, orElse: () => Sex.unknown);

AnimalStatus statusFromName(String? value) => AnimalStatus.values.firstWhere(
  (e) => e.name == value,
  orElse: () => AnimalStatus.active,
);

/// The litter's puppies, in name order — the order a breeder reads them off the
/// whelping box.
List<Animal> puppiesOf(List<Animal> animals, String litterId) =>
    animals.where((a) => a.litterId == litterId).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

Animal? animalById(List<Animal> animals, String? id) {
  if (id == null) return null;
  for (final animal in animals) {
    if (animal.id == id) return animal;
  }
  return null;
}

class Animal extends Equatable {
  const Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.sex,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.breed,
    this.birthDate,
    this.deathDate,
    this.color,
    this.registrationNo,
    this.registry,
    this.microchipId,
    this.microchipDate,
    this.damId,
    this.sireId,
    this.litterId,
    this.isBreedingStock = false,
    this.photoPath,
    this.notes,
  });

  final String id;
  final String name;

  /// Free-form on purpose (dog, cat, ...): breeders of other species should not
  /// be blocked by an enum we would have to migrate for every addition.
  final String species;
  final String? breed;
  final Sex sex;
  final int? birthDate;
  final int? deathDate;
  final String? color;
  final String? registrationNo;
  final String? registry;
  final String? microchipId;
  final int? microchipDate;
  final String? damId;
  final String? sireId;
  final String? litterId;
  final bool isBreedingStock;
  final String? photoPath;
  final String? notes;
  final AnimalStatus status;
  final int createdAt;
  final int updatedAt;

  Animal copyWith({
    String? name,
    String? species,
    String? breed,
    Sex? sex,
    int? birthDate,
    bool clearBirthDate = false,
    int? deathDate,
    String? color,
    String? registrationNo,
    String? registry,
    String? microchipId,
    int? microchipDate,
    String? damId,
    String? sireId,
    String? litterId,
    bool? isBreedingStock,
    String? photoPath,
    String? notes,
    AnimalStatus? status,
    int? updatedAt,
  }) {
    return Animal(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      deathDate: deathDate ?? this.deathDate,
      color: color ?? this.color,
      registrationNo: registrationNo ?? this.registrationNo,
      registry: registry ?? this.registry,
      microchipId: microchipId ?? this.microchipId,
      microchipDate: microchipDate ?? this.microchipDate,
      damId: damId ?? this.damId,
      sireId: sireId ?? this.sireId,
      litterId: litterId ?? this.litterId,
      isBreedingStock: isBreedingStock ?? this.isBreedingStock,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Animal fromMap(Map<String, Object?> map) {
    return Animal(
      id: map['id']! as String,
      name: map['name']! as String,
      species: map['species']! as String,
      breed: map['breed'] as String?,
      sex: sexFromName(map['sex'] as String?),
      birthDate: map['birth_date'] as int?,
      deathDate: map['death_date'] as int?,
      color: map['color'] as String?,
      registrationNo: map['registration_no'] as String?,
      registry: map['registry'] as String?,
      microchipId: map['microchip_id'] as String?,
      microchipDate: map['microchip_date'] as int?,
      damId: map['dam_id'] as String?,
      sireId: map['sire_id'] as String?,
      litterId: map['litter_id'] as String?,
      isBreedingStock: (map['is_breeding_stock'] as int? ?? 0) == 1,
      photoPath: map['photo_path'] as String?,
      notes: map['notes'] as String?,
      status: statusFromName(map['status'] as String?),
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex.name,
      'birth_date': birthDate,
      'death_date': deathDate,
      'color': color,
      'registration_no': registrationNo,
      'registry': registry,
      'microchip_id': microchipId,
      'microchip_date': microchipDate,
      'dam_id': damId,
      'sire_id': sireId,
      'litter_id': litterId,
      'is_breeding_stock': isBreedingStock ? 1 : 0,
      'photo_path': photoPath,
      'notes': notes,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    species,
    breed,
    sex,
    birthDate,
    deathDate,
    color,
    registrationNo,
    registry,
    microchipId,
    microchipDate,
    damId,
    sireId,
    litterId,
    isBreedingStock,
    photoPath,
    notes,
    status,
    createdAt,
    updatedAt,
  ];
}
