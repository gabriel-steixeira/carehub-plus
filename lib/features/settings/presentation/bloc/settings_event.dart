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

/// O dono digitou/alterou o número de WhatsApp para alertas de SOS.
class SettingsSosPhoneChangedEvent extends SettingsEvent {
  const SettingsSosPhoneChangedEvent({required this.phone});

  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// O dono alternou o canal de alerta de SOS (app ou também WhatsApp).
class SettingsSosChannelChangedEvent extends SettingsEvent {
  const SettingsSosChannelChangedEvent({required this.channel});

  final AlertChannel channel;

  @override
  List<Object?> get props => [channel];
}

/// Salva as preferências de alerta de SOS do dono (telefone + canal).
class SettingsSaveSosPreferencesEvent extends SettingsEvent {
  const SettingsSaveSosPreferencesEvent();
}

/// Resolve o caso de exclusão (quem é afetado) antes de abrir o fluxo.
class SettingsResolveDeletionEvent extends SettingsEvent {
  const SettingsResolveDeletionEvent();
}

/// Confirma a exclusão da conta após a reautenticação.
class SettingsDeleteAccountEvent extends SettingsEvent {
  const SettingsDeleteAccountEvent();
}
