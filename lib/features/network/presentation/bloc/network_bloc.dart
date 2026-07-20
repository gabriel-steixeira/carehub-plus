import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/network_member_model.dart';
import '../../data/repositories/network_repository.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc({required NetworkRepository repository})
      : _repository = repository,
        super(const NetworkState()) {
    on<NetworkLoadEvent>(_onLoad);
    on<NetworkAddMemberEvent>(_onAddMember);
    on<NetworkRemoveMemberEvent>(_onRemoveMember);
  }

  final NetworkRepository _repository;

  Future<void> _onLoad(
    NetworkLoadEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(status: NetworkStatus.loading));
    try {
      final members = await _repository.fetchMembers();
      emit(state.copyWith(status: NetworkStatus.success, members: members));
    } catch (e) {
      emit(state.copyWith(
        status: NetworkStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddMember(
    NetworkAddMemberEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(isAddingMember: true, addSuccess: false));
    try {
      final newMember = NetworkMemberModel(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        phone: event.phone,
        role: event.role,
        email: event.email,
        isOnline: false,
      );

      final added = await _repository.addMember(newMember);
      final updated = List<NetworkMemberModel>.from(state.members)..add(added);

      emit(state.copyWith(
        members: updated,
        isAddingMember: false,
        addSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isAddingMember: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRemoveMember(
    NetworkRemoveMemberEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      await _repository.removeMember(event.memberId);
      final updated =
          state.members.where((m) => m.id != event.memberId).toList();
      emit(state.copyWith(members: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
