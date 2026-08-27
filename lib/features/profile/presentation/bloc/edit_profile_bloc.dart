/*
 * CareHub Plus — Apresentação / BLoC de Edição de Perfil
 *
 * Carrega o perfil e o plano do cuidador e grava as alterações do formulário.
 * O carregamento e o salvamento têm status separados de propósito: uma falha ao
 * salvar não pode apagar o formulário que a cuidadora acabou de preencher.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../services/image_upload_service.dart';
import '../../data/repositories/caregiver_profile_repository.dart';
import '../../domain/entities/caregiver_gender.dart';
import '../../domain/entities/caregiver_profile_entity.dart';
import '../../../subscriptions/domain/entities/contracted_subscription_entity.dart';
import '../../../subscriptions/domain/entities/subscription_plan_entity.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  EditProfileBloc({
    required CaregiverProfileRepository repository,
    ImageUploadService? imageUploadService,
  }) : _repository = repository,
       _imageUploadService = imageUploadService ?? ImageUploadService(),
       super(const EditProfileState()) {
    on<EditProfileLoadEvent>(_onLoad);
    on<EditProfileSubmitEvent>(_onSubmit);
    on<EditProfilePhotoChangedEvent>(_onPhotoChanged);
  }

  final CaregiverProfileRepository _repository;
  final ImageUploadService _imageUploadService;

  Future<void> _onLoad(
    EditProfileLoadEvent event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(state.copyWith(status: EditProfileStatus.loading));
    try {
      final snapshot = await _repository.fetchProfileWithPlan();
      emit(
        state.copyWith(
          status: EditProfileStatus.success,
          profile: snapshot.profile,
          plan: snapshot.plan,
          contractedSubscription: snapshot.contractedSubscription,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: EditProfileStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onSubmit(
    EditProfileSubmitEvent event,
    Emitter<EditProfileState> emit,
  ) async {
    final current = state.profile;
    // Sem perfil carregado não há `id` para gravar — só acontece se um evento
    // chegar antes do carregamento terminar.
    if (current == null) return;

    final updated = current.copyWithEditableFields(
      name: event.name,
      email: event.email,
      phone: event.phone,
      birthDate: event.birthDate,
      gender: event.gender,
      photoBase64: event.photoBase64,
    );

    emit(state.copyWith(saveStatus: EditProfileSaveStatus.saving));
    try {
      await _repository.updateProfile(updated);
      emit(
        state.copyWith(
          profile: updated,
          saveStatus: EditProfileSaveStatus.success,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          saveStatus: EditProfileSaveStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  /// Converte a imagem para base64 e atualiza o estado local do perfil.
  /// A gravação no Firestore acontece quando o usuário clicar em "Salvar".
  Future<void> _onPhotoChanged(
    EditProfilePhotoChangedEvent event,
    Emitter<EditProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null) return;

    try {
      final base64 = await _imageUploadService.fileToBase64(event.imageFile);
      final updated = CaregiverProfileEntity(
        id: current.id,
        name: current.name,
        email: current.email,
        phone: current.phone,
        birthDate: current.birthDate,
        gender: current.gender,
        photoUrl: current.photoUrl,
        photoBase64: base64,
      );
      emit(state.copyWith(profile: updated));
    } catch (_) {
      // Falha silenciosa: a foto simplesmente não muda.
    }
  }
}
