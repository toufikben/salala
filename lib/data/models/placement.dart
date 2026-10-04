import 'package:equatable/equatable.dart';

/// One animal transferred to one buyer. This is what makes the export pack
/// valuable: the guarantee terms and contract file travel with the animal.
class Placement extends Equatable {
  const Placement({
    required this.id,
    required this.animalId,
    required this.createdAt,
    required this.updatedAt,
    this.buyerId,
    this.placedDate,
    this.price,
    this.currency,
    this.guaranteeTerms,
    this.contractFilePath,
    this.notes,
  });

  final String id;
  final String animalId;
  final String? buyerId;
  final int? placedDate;
  final double? price;
  final String? currency;
  final String? guaranteeTerms;
  final String? contractFilePath;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  Placement copyWith({
    String? animalId,
    String? buyerId,
    int? placedDate,
    double? price,
    bool clearPrice = false,
    String? currency,
    String? guaranteeTerms,
    String? contractFilePath,
    String? notes,
    int? updatedAt,
  }) {
    return Placement(
      id: id,
      animalId: animalId ?? this.animalId,
      buyerId: buyerId ?? this.buyerId,
      placedDate: placedDate ?? this.placedDate,
      price: clearPrice ? null : (price ?? this.price),
      currency: currency ?? this.currency,
      guaranteeTerms: guaranteeTerms ?? this.guaranteeTerms,
      contractFilePath: contractFilePath ?? this.contractFilePath,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Placement fromMap(Map<String, Object?> map) {
    return Placement(
      id: map['id']! as String,
      animalId: map['animal_id']! as String,
      buyerId: map['buyer_id'] as String?,
      placedDate: map['placed_date'] as int?,
      price: (map['price'] as num?)?.toDouble(),
      currency: map['currency'] as String?,
      guaranteeTerms: map['guarantee_terms'] as String?,
      contractFilePath: map['contract_file_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'animal_id': animalId,
      'buyer_id': buyerId,
      'placed_date': placedDate,
      'price': price,
      'currency': currency,
      'guarantee_terms': guaranteeTerms,
      'contract_file_path': contractFilePath,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    animalId,
    buyerId,
    placedDate,
    price,
    currency,
    guaranteeTerms,
    contractFilePath,
    notes,
    createdAt,
    updatedAt,
  ];
}
