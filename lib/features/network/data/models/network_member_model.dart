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

/// Whether a member is the primary contact or a support contact.
enum MemberType {
  primary('Principal', 'primary'),
  support('Apoio', 'support');

  const MemberType(this.label, this.value);
  final String label;
  final String value;

  static MemberType fromValue(String val) {
    return MemberType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => MemberType.support,
    );
  }
}

/// Level of access a member has to the care recipient's information.
enum AccessLevel {
  full(
    'Acesso Total',
    'full',
    'Pode ver tudo e editar tarefas/membros.',
  ),
  partial(
    'Acesso Parcial',
    'partial',
    'Selecione as permissões específicas para este membro.',
  ),
  readonly(
    'Apenas Visualização',
    'readonly',
    'Pode ver a rotina, mas não pode alterar nada.',
  );

  const AccessLevel(this.label, this.value, this.description);
  final String label;
  final String value;

  /// Plain-language explanation of what this level allows, shown to the
  /// caregiver while choosing the level.
  final String description;

  static AccessLevel fromValue(String val) {
    return AccessLevel.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AccessLevel.full,
    );
  }
}

/// Individual app area a member can be granted when the access level is
/// [AccessLevel.partial].
enum NetworkPermission {
  chat('Chat', 'chat'),
  cora('Cora', 'cora'),
  sos('SOS', 'sos'),
  task('Tarefa', 'task');

  const NetworkPermission(this.label, this.value);
  final String label;
  final String value;

  /// Returns `null` when [val] does not match any known permission, so unknown
  /// values coming from Firestore are ignored instead of breaking the parse.
  static NetworkPermission? fromValue(String val) {
    for (final permission in NetworkPermission.values) {
      if (permission.value == val) return permission;
    }
    return null;
  }
}

/// Model representing a support network member.
class NetworkMemberModel extends Equatable {
  const NetworkMemberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.relationship,
    this.memberType = MemberType.support,
    this.accessLevel = AccessLevel.full,
    this.permissions = const [],
    this.email,
    this.photoUrl,
    this.isOnline = false,
    this.careRecipientId,
  });

  final String id;
  final String name;
  final String phone;
  final NetworkRole role;

  /// Free-text relationship label shown on the card (e.g. "Filha", "Genro").
  final String? relationship;

  /// Whether this member is a primary or support contact.
  final MemberType memberType;

  /// Level of access this member has.
  final AccessLevel accessLevel;

  /// Areas granted to this member. Only meaningful when [accessLevel] is
  /// [AccessLevel.partial]; empty for every other level.
  final List<NetworkPermission> permissions;

  final String? email;
  final String? photoUrl;
  final bool isOnline;

  /// FK para o perfil cuidado — permite filtrar membros por Care Recipient.
  /// Nulo em registros criados antes deste campo existir (retrocompatível).
  final String? careRecipientId;

  factory NetworkMemberModel.fromJson(Map<String, dynamic> json) {
    return NetworkMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: NetworkRole.fromValue(json['role'] as String? ?? 'family'),
      relationship: json['relationship'] as String?,
      memberType: MemberType.fromValue(json['memberType'] as String? ?? 'support'),
      accessLevel: AccessLevel.fromValue(json['accessLevel'] as String? ?? 'full'),
      permissions: _permissionsFromJson(json['permissions']),
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      careRecipientId: json['careRecipientId'] as String?,
    );
  }

  /// Reads the stored permission list, dropping anything unrecognized.
  static List<NetworkPermission> _permissionsFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map(NetworkPermission.fromValue)
        .whereType<NetworkPermission>()
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.value,
      'relationship': relationship,
      'memberType': memberType.value,
      'accessLevel': accessLevel.value,
      'permissions': permissions.map((p) => p.value).toList(),
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'careRecipientId': careRecipientId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        role,
        relationship,
        memberType,
        accessLevel,
        permissions,
        email,
        photoUrl,
        isOnline,
        careRecipientId,
      ];
}
