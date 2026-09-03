part of 'network_bloc.dart';

abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object?> get props => [];
}

class NetworkLoadEvent extends NetworkEvent {
  const NetworkLoadEvent();
}

class NetworkAddMemberEvent extends NetworkEvent {
  const NetworkAddMemberEvent({
    required this.name,
    required this.phone,
    required this.role,
    this.relationship,
    this.email,
    this.accessLevel = AccessLevel.full,
    this.permissions = const [],
    this.imageFile,
    this.removePhoto = false,
    this.careRecipientId,
  });

  final String name;
  final String phone;
  final NetworkRole role;
  final String? relationship;
  final String? email;
  final AccessLevel accessLevel;
  final List<NetworkPermission> permissions;
  final File? imageFile;
  final bool removePhoto;
  final String? careRecipientId;

  @override
  List<Object?> get props => [
    name,
    phone,
    role,
    relationship,
    email,
    accessLevel,
    permissions,
    imageFile,
    removePhoto,
    careRecipientId,
  ];
}

class NetworkUpdateMemberEvent extends NetworkEvent {
  const NetworkUpdateMemberEvent({
    required this.memberId,
    required this.name,
    required this.phone,
    required this.role,
    required this.accessLevel,
    this.relationship,
    this.email,
    this.permissions = const [],
    this.imageFile,
    this.removePhoto = false,
    this.careRecipientId,
  });

  final String memberId;
  final String name;
  final String phone;
  final NetworkRole role;
  final String? relationship;
  final String? email;
  final AccessLevel accessLevel;
  final List<NetworkPermission> permissions;
  final File? imageFile;
  final bool removePhoto;
  final String? careRecipientId;

  @override
  List<Object?> get props => [
    memberId,
    name,
    phone,
    role,
    relationship,
    email,
    accessLevel,
    permissions,
    imageFile,
    removePhoto,
    careRecipientId,
  ];
}

class NetworkRemoveMemberEvent extends NetworkEvent {
  const NetworkRemoveMemberEvent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}
