import 'package:equatable/equatable.dart';

/// Model representing an emergency contact (SAMU, doctor, family).
class EmergencyContactModel extends Equatable {
  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.isService = false,
  });

  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final bool isService;

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        relationship,
        isPrimary,
        isService,
      ];
}
