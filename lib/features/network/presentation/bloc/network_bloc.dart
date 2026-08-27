import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/image_upload_service.dart';

import '../../data/models/network_member_model.dart';
import '../../data/repositories/network_repository.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc({
    required NetworkRepository repository,
    ImageUploadService? imageUploadService,
    this.careRecipientId,
  }) : _repository = repository,
       _imageUploadService = imageUploadService ?? ImageUploadService(),
       super(const NetworkState()) {
    on<NetworkLoadEvent>(_onLoad);
    on<NetworkAddMemberEvent>(_onAddMember);
    on<NetworkUpdateMemberEvent>(_onUpdateMember);
    on<NetworkRemoveMemberEvent>(_onRemoveMember);
  }

  final NetworkRepository _repository;
  final ImageUploadService _imageUploadService;
  final String? careRecipientId;

  /// Permissões só existem no nível "Acesso Parcial" — nos outros níveis o
  /// acesso é definido pelo próprio nível, então a lista é descartada.
  List<NetworkPermission> _resolvePermissions(
    AccessLevel accessLevel,
    List<NetworkPermission> permissions,
  ) {
    return accessLevel == AccessLevel.partial ? permissions : const [];
  }

  Future<void> _onLoad(
    NetworkLoadEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(status: NetworkStatus.loading));
    try {
      final members = await _repository.fetchMembers(
        careRecipientId: careRecipientId,
      );
      emit(state.copyWith(status: NetworkStatus.success, members: members));
    } catch (e) {
      emit(
        state.copyWith(
          status: NetworkStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddMember(
    NetworkAddMemberEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(isAddingMember: true, addSuccess: false));
    try {
      String? photoUrl;
      if (event.imageFile != null) {
        photoUrl = await _imageUploadService.fileToBase64(event.imageFile!);
      }

      final newMember = NetworkMemberModel(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        phone: event.phone,
        role: event.role,
        relationship: event.relationship,
        accessLevel: event.accessLevel,
        permissions: _resolvePermissions(event.accessLevel, event.permissions),
        email: event.email,
        photoUrl: photoUrl,
        isOnline: false,
        careRecipientId: event.careRecipientId ?? careRecipientId,
      );

      final added = await _repository.addMember(newMember);
      final updated = List<NetworkMemberModel>.from(state.members)..add(added);

      emit(
        state.copyWith(
          members: updated,
          isAddingMember: false,
          addSuccess: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isAddingMember: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateMember(
    NetworkUpdateMemberEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(isUpdatingMember: true, updateSuccess: false));
    try {
      final current = state.members.firstWhere(
        (member) => member.id == event.memberId,
      );
      String? photoUrl = current.photoUrl;
      if (event.removePhoto) {
        photoUrl = null;
      } else if (event.imageFile != null) {
        photoUrl = await _imageUploadService.fileToBase64(event.imageFile!);
      }
      final updatedMember = NetworkMemberModel(
        id: current.id,
        name: event.name,
        phone: event.phone,
        role: event.role,
        relationship: event.relationship,
        memberType: current.memberType,
        accessLevel: event.accessLevel,
        permissions: _resolvePermissions(event.accessLevel, event.permissions),
        email: event.email,
        photoUrl: photoUrl,
        isOnline: current.isOnline,
        careRecipientId: event.careRecipientId ?? current.careRecipientId,
      );

      final savedMember = await _repository.updateMember(updatedMember);
      final updatedMembers = state.members
          .map((member) => member.id == savedMember.id ? savedMember : member)
          .toList();

      emit(
        state.copyWith(
          members: updatedMembers,
          isUpdatingMember: false,
          updateSuccess: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isUpdatingMember: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemoveMember(
    NetworkRemoveMemberEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      await _repository.removeMember(event.memberId);
      final updated = state.members
          .where((m) => m.id != event.memberId)
          .toList();
      emit(state.copyWith(members: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
