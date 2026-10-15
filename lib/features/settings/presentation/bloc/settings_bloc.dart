import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/data/models/caregiver_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/delete_account_preview.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required SettingsRepository repository,
    AccountRepository? accountRepository,
  })  : _repository = repository,
        _accountRepository = accountRepository ?? AccountRepository(),
        super(const SettingsState()) {
    on<SettingsLoadEvent>(_onLoad);
    on<SettingsToggleNotificationEvent>(_onToggleNotification);
    on<SettingsResolveDeletionEvent>(_onResolveDeletion);
    on<SettingsDeleteAccountEvent>(_onDeleteAccount);
  }

  final SettingsRepository _repository;
  final AccountRepository _accountRepository;

  Future<void> _onLoad(
    SettingsLoadEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final caregiver = await _repository.fetchCaregiver();
      final notifs = await _repository.fetchNotificationSettings();
      emit(state.copyWith(
        status: SettingsStatus.success,
        caregiver: caregiver,
        notifications: notifs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggleNotification(
    SettingsToggleNotificationEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedMap = Map<String, bool>.from(state.notifications)
      ..[event.key] = event.value;

    emit(state.copyWith(notifications: updatedMap));

    try {
      await _repository.updateNotificationSetting(event.key, event.value);
    } catch (e) {
      // Revert if error
      final revertedMap = Map<String, bool>.from(state.notifications)
        ..[event.key] = !event.value;
      emit(state.copyWith(notifications: revertedMap, errorMessage: e.toString()));
    }
  }

  Future<void> _onResolveDeletion(
    SettingsResolveDeletionEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(deletionStatus: SettingsDeletionStatus.resolving));
    try {
      final preview = await _accountRepository.resolveDeletionCase();
      emit(state.copyWith(
        deletionStatus: SettingsDeletionStatus.ready,
        deletionPreview: preview,
      ));
    } catch (e) {
      emit(state.copyWith(
        deletionStatus: SettingsDeletionStatus.failure,
        deletionError: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteAccount(
    SettingsDeleteAccountEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(deletionStatus: SettingsDeletionStatus.deleting));
    try {
      await _accountRepository.deleteAccount();
      emit(state.copyWith(deletionStatus: SettingsDeletionStatus.deleted));
    } catch (e) {
      emit(state.copyWith(
        deletionStatus: SettingsDeletionStatus.failure,
        deletionError: e.toString(),
      ));
    }
  }
}
