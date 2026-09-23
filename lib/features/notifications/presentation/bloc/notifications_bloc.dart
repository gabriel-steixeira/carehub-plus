/*
 * CareHub Plus — Apresentação / BLoC de Notificações
 *
 * Orquestra a tela de Notificações: carrega as preferências e a foto do
 * cuidador, e salva cada interruptor alterado.
 *
 * O interruptor é atualizado na tela antes da resposta do Firestore (atualização
 * otimista) para o toque parecer instantâneo; se a gravação falhar, o valor
 * anterior é restaurado e a mensagem de erro é publicada no estado.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../assistants/data/repositories/caregiver_avatar_repository.dart';
import '../../data/repositories/notification_preferences_repository.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/notification_preferences_entity.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required NotificationPreferencesRepository repository,
    required CaregiverAvatarRepository avatarRepository,
  })  : _repository = repository,
        _avatarRepository = avatarRepository,
        super(const NotificationsState()) {
    on<NotificationsLoadEvent>(_onLoad);
    on<NotificationsTogglePreferenceEvent>(_onTogglePreference);
  }

  final NotificationPreferencesRepository _repository;
  final CaregiverAvatarRepository _avatarRepository;

  Future<void> _onLoad(
    NotificationsLoadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationsStatus.loading,
      clearErrorMessage: true,
    ));

    try {
      final preferences = await _repository.fetchPreferences();
      emit(state.copyWith(
        status: NotificationsStatus.success,
        preferences: preferences,
        caregiverPhotoUrl: await _fetchPhotoUrl(),
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  /// A foto é enfeite do cabeçalho: se falhar, a tela abre com o avatar
  /// genérico em vez de mostrar erro por causa de uma imagem.
  Future<String?> _fetchPhotoUrl() async {
    try {
      return await _avatarRepository.fetchPhotoUrl();
    } on AppException {
      return null;
    }
  }

  Future<void> _onTogglePreference(
    NotificationsTogglePreferenceEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final previous = state.preferences;
    if (previous == null) return;

    emit(state.copyWith(
      preferences: previous.copyWithPreference(event.preference, event.enabled),
      clearErrorMessage: true,
    ));

    try {
      await _repository.updatePreference(event.preference, event.enabled);
    } on AppException catch (e) {
      emit(state.copyWith(preferences: previous, errorMessage: e.message));
    }
  }
}
