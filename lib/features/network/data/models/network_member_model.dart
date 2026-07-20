import 'package:equatable/equatable.dart';

/// Role/Permission in the Support Network
enum NetworkRole {
  admin('Administrador', 'admin'),
  caregiver('Cuidador Principal', 'caregiver'),
  family('Familiar / Apoio', 'family'),
  doctor('Profissional de Saúde', 'doctor');

  const NetworkRole(this.label, this.value);
  final String label;
  final String value;

  static NetworkRole fromValue(String val) {
    return NetworkRole.values.firstWhere(
      (e) => e.value == val,
      orElse: () => NetworkRole.family,
    );
  }
}

/// Model representing a support network member.
class NetworkMemberModel extends Equatable {
  const NetworkMemberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.photoUrl,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String phone;
  final NetworkRole role;
  final String? email;
  final String? photoUrl;
  final bool isOnline;

  factory NetworkMemberModel.fromJson(Map<String, dynamic> json) {
    return NetworkMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: NetworkRole.fromValue(json['role'] as String? ?? 'family'),
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.value,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
    };
  }

  @override
  List<Object?> get props => [id, name, phone, role, email, photoUrl, isOnline];
}
