part of 'network_bloc.dart';

enum NetworkStatus { initial, loading, success, failure }

class NetworkState extends Equatable {
  const NetworkState({
    this.status = NetworkStatus.initial,
    this.members = const [],
    this.isAddingMember = false,
    this.addSuccess = false,
    this.isUpdatingMember = false,
    this.updateSuccess = false,
    this.errorMessage,
    this.lastInvite,
    this.inviteError,
    this.isChangingAccess = false,
  });

  final NetworkStatus status;
  final List<NetworkMemberModel> members;
  final bool isAddingMember;
  final bool addSuccess;
  final bool isUpdatingMember;
  final bool updateSuccess;
  final String? errorMessage;

  /// Invite just created, ready for the caregiver to share.
  final InviteShareEntity? lastInvite;

  /// Why the invite (or a revoke/cancel) failed — the member itself was saved.
  final String? inviteError;

  /// A revoke or cancel is in progress.
  final bool isChangingAccess;

  NetworkState copyWith({
    NetworkStatus? status,
    List<NetworkMemberModel>? members,
    bool? isAddingMember,
    bool? addSuccess,
    bool? isUpdatingMember,
    bool? updateSuccess,
    String? errorMessage,
    InviteShareEntity? lastInvite,
    String? inviteError,
    bool? isChangingAccess,
    bool clearInvite = false,
  }) {
    return NetworkState(
      status: status ?? this.status,
      members: members ?? this.members,
      isAddingMember: isAddingMember ?? this.isAddingMember,
      addSuccess: addSuccess ?? this.addSuccess,
      isUpdatingMember: isUpdatingMember ?? this.isUpdatingMember,
      updateSuccess: updateSuccess ?? this.updateSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      lastInvite: clearInvite ? null : lastInvite ?? this.lastInvite,
      inviteError: clearInvite ? null : inviteError ?? this.inviteError,
      isChangingAccess: isChangingAccess ?? this.isChangingAccess,
    );
  }

  @override
  List<Object?> get props => [
        status,
        members,
        isAddingMember,
        addSuccess,
        isUpdatingMember,
        updateSuccess,
        errorMessage,
        lastInvite,
        inviteError,
        isChangingAccess,
      ];
}
