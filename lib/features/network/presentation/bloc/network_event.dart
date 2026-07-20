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
    this.email,
  });

  final String name;
  final String phone;
  final NetworkRole role;
  final String? email;

  @override
  List<Object?> get props => [name, phone, role, email];
}

class NetworkRemoveMemberEvent extends NetworkEvent {
  const NetworkRemoveMemberEvent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}
