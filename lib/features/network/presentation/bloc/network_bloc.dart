import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../services/selected_profile_service.dart';

import '../../../home/data/repositories/home_repository.dart';
import '../../../invites/data/repositories/invites_repository.dart';
import '../../../invites/domain/entities/invite_channel.dart';
import '../../../invites/domain/entities/invite_share_entity.dart';
import '../../data/models/network_member_model.dart';
import '../../data/repositories/network_repository.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc({
    required NetworkRepository repository,
    ImageUploadService? imageUploadService,
    HomeRepository? homeRepository,
    InvitesRepository? invitesRepository,
    this.careRecipientId,
  }) : _repository = repository,
       _imageUploadService = imageUploadService ?? ImageUploadService(),
       _homeRepository = homeRepository,
       _invitesRepository = invitesRepository,
       super(const NetworkState()) {
    on<NetworkLoadEvent>(_onLoad);
    on<NetworkAddMemberEvent>(_onAddMember);
    on<NetworkUpdateMemberEvent>(_onUpdateMember);
    on<NetworkRemoveMemberEvent>(_onRemoveMember);
    on<NetworkRevokeAccessEvent>(_onRevokeAccess);
    on<NetworkCancelInviteEvent>(_onCancelInvite);
    on<NetworkInviteHandledEvent>(
      (_, emit) => emit(state.copyWith(clearInvite: true)),
    );
  }

  final NetworkRepository _repository;

  /// Created on first use, so screens that never invite don't touch the
  /// Cloud Functions SDK.
  InvitesRepository? _invitesRepository;
  InvitesRepository get _invites =>
      _invitesRepository ??= InvitesRepository();
  final ImageUploadService _imageUploadService;
  final String? careRecipientId;

  /// Criado sob demanda para não instanciar o Firebase quando o perfil já
  /// chega pela navegação.
  HomeRepository? _homeRepository;

  /// Perfil cuidado ao qual a tela está vinculada. Tudo que é listado ou
  /// cadastrado aqui pertence a ele — não existe membro "compartilhado".
  String? _resolvedCareRecipientId;

  /// Resolve o perfil na ordem: id de navegação → perfil salvo pela seleção
  /// do usuário → primeiro perfil cadastrado. Mesma ordem de Tarefas e SOS,
  /// para que as três telas mostrem sempre o mesmo assistido.
  Future<String?> _resolveCareRecipientId() async {
    final navigationId = careRecipientId;
    if (navigationId != null && navigationId.isNotEmpty) return navigationId;

    final profiles = await (_homeRepository ??= HomeRepository())
        .fetchCareRecipients();
    bool existsInList(String id) => profiles.any((p) => p.id == id);

    try {
      final service = await SelectedProfileService.create();
      final savedId = service.getSelectedProfileId();
      if (savedId != null && existsInList(savedId)) return savedId;
    } catch (_) {
      // Falha ao ler a seleção não impede o carregamento da rede.
    }

    return profiles.isNotEmpty ? profiles.first.id : null;
  }

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
      _resolvedCareRecipientId ??= await _resolveCareRecipientId();
      final members = await _repository.fetchMembers(
        careRecipientId: _resolvedCareRecipientId,
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
    emit(
      state.copyWith(
        isAddingMember: true,
        addSuccess: false,
        clearInvite: true,
      ),
    );
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
        careRecipientId: event.careRecipientId ?? _resolvedCareRecipientId,
        accessDurationHours: event.accessDurationHours,
        alertChannels: event.alertChannels,
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

      // The member is saved first: the backend reads the deadline from it.
      await _sendInvite(added.id, event.inviteChannel, emit);
    } catch (e) {
      emit(state.copyWith(isAddingMember: false, errorMessage: e.toString()));
    }
  }

  /// Creates the invite and publishes it for the page to share. A failure
  /// here does not undo the member, which is already saved.
  Future<void> _sendInvite(
    String memberId,
    InviteChannel? channel,
    Emitter<NetworkState> emit,
  ) async {
    if (channel == null) return;
    try {
      final invite = await _invites.createInvite(
        memberId: memberId,
        channel: channel,
      );
      emit(
        state.copyWith(
          lastInvite: invite,
          members: _withStatus(memberId, MemberInviteStatus.pending),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(inviteError: error.message));
    }
  }

  /// Local copy of the list with a new invite status (the backend confirms
  /// it on the next load).
  List<NetworkMemberModel> _withStatus(
    String memberId,
    MemberInviteStatus status,
  ) {
    return state.members.map((member) {
      if (member.id != memberId) return member;
      return NetworkMemberModel(
        id: member.id,
        name: member.name,
        phone: member.phone,
        role: member.role,
        relationship: member.relationship,
        memberType: member.memberType,
        accessLevel: member.accessLevel,
        permissions: member.permissions,
        email: member.email,
        photoUrl: member.photoUrl,
        isOnline: member.isOnline,
        careRecipientId: member.careRecipientId,
        accessDurationHours: member.accessDurationHours,
        alertChannels: member.alertChannels,
        inviteStatus: status,
        accessExpiresAt: status == MemberInviteStatus.active
            ? member.accessExpiresAt
            : null,
      );
    }).toList();
  }

  Future<void> _onRevokeAccess(
    NetworkRevokeAccessEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(isChangingAccess: true, clearInvite: true));
    try {
      await _invites.revokeAccess(event.memberId);
      emit(
        state.copyWith(
          isChangingAccess: false,
          members: _withStatus(event.memberId, MemberInviteStatus.revoked),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(isChangingAccess: false, inviteError: error.message));
    }
  }

  Future<void> _onCancelInvite(
    NetworkCancelInviteEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(state.copyWith(isChangingAccess: true, clearInvite: true));
    try {
      await _invites.cancelInvite(event.memberId);
      emit(
        state.copyWith(
          isChangingAccess: false,
          members: _withStatus(event.memberId, MemberInviteStatus.revoked),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(isChangingAccess: false, inviteError: error.message));
    }
  }

  Future<void> _onUpdateMember(
    NetworkUpdateMemberEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdatingMember: true,
        updateSuccess: false,
        clearInvite: true,
      ),
    );
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
        accessDurationHours: event.accessDurationHours,
        alertChannels: event.alertChannels,
        // Backend-owned fields are not saved, only kept for the screen.
        inviteStatus: current.inviteStatus,
        accessExpiresAt: current.accessExpiresAt,
      );

      await _repository.updateMember(updatedMember);
      final updatedMembers = state.members
          .map((member) => member.id == updatedMember.id ? updatedMember : member)
          .toList();

      emit(
        state.copyWith(
          members: updatedMembers,
          isUpdatingMember: false,
          updateSuccess: true,
        ),
      );

      await _sendInvite(updatedMember.id, event.inviteChannel, emit);
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
