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
    this.accessDurationHours,
    this.alertChannels = AlertChannel.all,
    this.inviteChannel,
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

  /// `null` = unlimited.
  final int? accessDurationHours;
  final List<AlertChannel> alertChannels;

  /// Channel of the invite to create after saving; `null` = don't invite now.
  final InviteChannel? inviteChannel;

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
    accessDurationHours,
    alertChannels,
    inviteChannel,
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
    this.accessDurationHours,
    this.alertChannels = AlertChannel.all,
    this.inviteChannel,
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

  /// `null` = unlimited.
  final int? accessDurationHours;
  final List<AlertChannel> alertChannels;

  /// New invite to send after saving (e.g. resend); `null` = don't send.
  final InviteChannel? inviteChannel;

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
    accessDurationHours,
    alertChannels,
    inviteChannel,
  ];
}

class NetworkRemoveMemberEvent extends NetworkEvent {
  const NetworkRemoveMemberEvent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

/// Removes the member's access right away (app and WhatsApp).
class NetworkRevokeAccessEvent extends NetworkEvent {
  const NetworkRevokeAccessEvent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

/// Cancels the member's pending invite.
class NetworkCancelInviteEvent extends NetworkEvent {
  const NetworkCancelInviteEvent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

/// The share sheet was shown; clears the invite from the state.
class NetworkInviteHandledEvent extends NetworkEvent {
  const NetworkInviteHandledEvent();
}
