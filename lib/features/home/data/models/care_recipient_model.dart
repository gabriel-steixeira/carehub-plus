import 'package:equatable/equatable.dart';

import 'care_recipient_type.dart';

/// Model representing a Care Recipient (person or pet being cared for).
class CareRecipientModel extends Equatable {
  const CareRecipientModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.unreadNotificationsCount = 0,
    this.type = 'person',
    this.dateOfBirth,
    this.recipientType,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final int unreadNotificationsCount;

  /// Legacy string type ('person' or 'pet') — kept for backwards compat.
  final String type;

  /// Typed care recipient category (child, elderly, pet, other).
  final CareRecipientType? recipientType;

  /// Optional date of birth.
  final DateTime? dateOfBirth;

  /// Creates a CareRecipientModel from a JSON map.
  factory CareRecipientModel.fromJson(Map<String, dynamic> json) {
    return CareRecipientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
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
    int? unreadNotificationsCount,
    String? type,
    CareRecipientType? recipientType,
    DateTime? dateOfBirth,
  }) {
    return CareRecipientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
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
        unreadNotificationsCount,
        type,
        recipientType,
        dateOfBirth,
      ];
}
