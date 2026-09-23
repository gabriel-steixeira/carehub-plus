part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega as preferências gravadas e a foto do cuidador.
class NotificationsLoadEvent extends NotificationsEvent {
  const NotificationsLoadEvent();
}

/// Liga ou desliga uma preferência.
class NotificationsTogglePreferenceEvent extends NotificationsEvent {
  const NotificationsTogglePreferenceEvent({
    required this.preference,
    required this.enabled,
  });

  final NotificationPreference preference;
  final bool enabled;

  @override
  List<Object?> get props => [preference, enabled];
}
