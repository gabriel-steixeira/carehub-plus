part of 'network_bloc.dart';

enum NetworkStatus { initial, loading, success, failure }

class NetworkState extends Equatable {
  const NetworkState({
    this.status = NetworkStatus.initial,
    this.members = const [],
    this.isAddingMember = false,
    this.addSuccess = false,
    this.errorMessage,
  });

  final NetworkStatus status;
  final List<NetworkMemberModel> members;
  final bool isAddingMember;
  final bool addSuccess;
  final String? errorMessage;

  NetworkState copyWith({
    NetworkStatus? status,
    List<NetworkMemberModel>? members,
    bool? isAddingMember,
    bool? addSuccess,
    String? errorMessage,
  }) {
    return NetworkState(
      status: status ?? this.status,
      members: members ?? this.members,
      isAddingMember: isAddingMember ?? this.isAddingMember,
      addSuccess: addSuccess ?? this.addSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, members, isAddingMember, addSuccess, errorMessage];
}
