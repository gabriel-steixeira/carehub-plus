import 'package:equatable/equatable.dart';

import 'care_recipient_type.dart';

/// Model representing a Care Recipient (person or pet being cared for).
class CareRecipientModel extends Equatable {
  const CareRecipientModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.photoBase64,
    this.unreadNotificationsCount = 0,
    this.type = 'person',
    this.dateOfBirth,
    this.recipientType,
  });

  final String id;
  final String name;

  /// URL-based photo (e.g. from Google Sign-In or external source).
  final String? photoUrl;

  /// Base64-encoded photo stored directly in Firestore.
  final String? photoBase64;

  final int unreadNotificationsCount;

  /// Legacy string type ('person' or 'pet') — kept for backwards compat.
  final String type;

  /// Typed care recipient category (child, elderly, pet, other).
  final CareRecipientType? recipientType;

  /// Optional date of birth.
  final DateTime? dateOfBirth;

  /// Returns true if this profile has any photo (URL or base64).
  bool get hasPhoto => photoUrl != null || photoBase64 != null;

  /// Creates a CareRecipientModel from a JSON map.
  factory CareRecipientModel.fromJson(Map<String, dynamic> json) {
    return CareRecipientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      photoBase64: json['photoBase64'] as String?,
      unreadNotificationsCount: json['unreadNotificationsCount'] as int? ?? 0,
      type: json['type'] as String? ?? 'person',
      recipientType: json['recipientType'] != null
          ? CareRecipientType.fromValue(json['recipientType'] as String)
          : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
    );
  }

  /// Converts the CareRecipientModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'unreadNotificationsCount': unreadNotificationsCount,
      'type': type,
      'recipientType': recipientType?.value,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }

  /// Creates a copy of this CareRecipientModel with the given fields replaced.
  CareRecipientModel copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? photoBase64,
    int? unreadNotificationsCount,
    String? type,
    CareRecipientType? recipientType,
    DateTime? dateOfBirth,
  }) {
    return CareRecipientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      type: type ?? this.type,
      recipientType: recipientType ?? this.recipientType,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        photoUrl,
        photoBase64,
        unreadNotificationsCount,
        type,
        recipientType,
        dateOfBirth,
      ];
}
