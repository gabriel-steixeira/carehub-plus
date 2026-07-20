part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLoadEvent extends SettingsEvent {
  const SettingsLoadEvent();
}

class SettingsToggleNotificationEvent extends SettingsEvent {
  const SettingsToggleNotificationEvent({
    required this.key,
    required this.value,
  });

  final String key;
  final bool value;

  @override
  List<Object?> get props => [key, value];
}
