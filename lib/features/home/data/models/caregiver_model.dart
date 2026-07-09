import 'package:equatable/equatable.dart';

/// Model representing the authenticated Caregiver (account owner).
class CaregiverModel extends Equatable {
  const CaregiverModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  /// Creates a CaregiverModel from a JSON map.
  factory CaregiverModel.fromJson(Map<String, dynamic> json) {
    return CaregiverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// Converts the CaregiverModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  /// Creates a copy of this CaregiverModel with the given fields replaced.
  CaregiverModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, email, photoUrl];
}
