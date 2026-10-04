import 'package:equatable/equatable.dart';

class Buyer extends Equatable {
  const Buyer({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.email,
    this.countryCode,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? countryCode;
  final int createdAt;
  final int updatedAt;

  Buyer copyWith({
    String? name,
    String? phone,
    String? email,
    String? countryCode,
    int? updatedAt,
  }) {
    return Buyer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      countryCode: countryCode ?? this.countryCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Buyer fromMap(Map<String, Object?> map) {
    return Buyer(
      id: map['id']! as String,
      name: map['name']! as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      countryCode: map['country_code'] as String?,
      createdAt: map['created_at']! as int,
      updatedAt: map['updated_at']! as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'country_code': countryCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    phone,
    email,
    countryCode,
    createdAt,
    updatedAt,
  ];
}
