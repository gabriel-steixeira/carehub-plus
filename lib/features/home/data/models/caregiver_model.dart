import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing the authenticated Caregiver (account owner).
class CaregiverModel extends Equatable {
  const CaregiverModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.photoBase64,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? photoBase64;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Returns true if this caregiver has any photo (URL or base64).
  bool get hasPhoto =>
      (photoUrl != null && photoUrl!.isNotEmpty) || photoBase64 != null;

  /// Creates a CaregiverModel from a JSON map.
  factory CaregiverModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      } else if (value is DateTime) {
        return value;
      }
      return null;
    }

    return CaregiverModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      photoBase64: json['photoBase64'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  /// Converts the CaregiverModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  /// Creates a copy of this CaregiverModel with the given fields replaced.
  CaregiverModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? photoBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, photoUrl, photoBase64, createdAt, updatedAt];
}


