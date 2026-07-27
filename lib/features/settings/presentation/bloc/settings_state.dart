part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, success, failure }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.caregiver,
    this.notifications = const {
      'pushEnabled': true,
      'medicationReminders': true,
      'coraProactiveAlerts': true,
      'networkChatNotifications': true,
    },
    this.errorMessage,
  });

  final SettingsStatus status;
  final CaregiverModel? caregiver;
  final Map<String, bool> notifications;
  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    CaregiverModel? caregiver,
    Map<String, bool>? notifications,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      caregiver: caregiver ?? this.caregiver,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, caregiver, notifications, errorMessage];
}
