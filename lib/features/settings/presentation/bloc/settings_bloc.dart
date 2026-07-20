import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsState()) {
    on<SettingsLoadEvent>(_onLoad);
    on<SettingsToggleNotificationEvent>(_onToggleNotification);
  }

  final SettingsRepository _repository;

  Future<void> _onLoad(
    SettingsLoadEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final notifs = await _repository.fetchNotificationSettings();
      emit(state.copyWith(
        status: SettingsStatus.success,
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
}
