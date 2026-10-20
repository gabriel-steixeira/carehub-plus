import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/data/models/caregiver_model.dart';
import '../../../network/data/models/network_member_model.dart';
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
    on<SettingsSosPhoneChangedEvent>(_onSosPhoneChanged);
    on<SettingsSosChannelChangedEvent>(_onSosChannelChanged);
    on<SettingsSaveSosPreferencesEvent>(_onSaveSosPreferences);
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
        sosPhone: caregiver.phone ?? '',
        sosAlertChannel: caregiver.sosAlertChannel,
        sosSaveStatus: SettingsSosSaveStatus.idle,
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

  void _onSosPhoneChanged(
    SettingsSosPhoneChangedEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(
      sosPhone: event.phone,
      sosSaveStatus: SettingsSosSaveStatus.idle,
    ));
  }

  void _onSosChannelChanged(
    SettingsSosChannelChangedEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(
      sosAlertChannel: event.channel,
      sosSaveStatus: SettingsSosSaveStatus.idle,
    ));
  }

  Future<void> _onSaveSosPreferences(
    SettingsSaveSosPreferencesEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(sosSaveStatus: SettingsSosSaveStatus.saving));
    try {
      final trimmedPhone = state.sosPhone.trim();
      final phone = trimmedPhone.isEmpty ? null : trimmedPhone;
      await _repository.updateSosAlertPreferences(
        phone: phone,
        channel: state.sosAlertChannel,
      );
      final updatedCaregiver = state.caregiver?.copyWith(
        phone: phone,
        sosAlertChannel: state.sosAlertChannel,
      );
      emit(state.copyWith(
        sosSaveStatus: SettingsSosSaveStatus.saved,
        caregiver: updatedCaregiver,
      ));
    } catch (e) {
      emit(state.copyWith(
        sosSaveStatus: SettingsSosSaveStatus.failure,
        errorMessage: e.toString(),
      ));
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
