part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, success, failure }

/// Estágio do fluxo de exclusão da conta (independente de [SettingsStatus]).
enum SettingsDeletionStatus { idle, resolving, ready, deleting, deleted, failure }

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
    this.deletionStatus = SettingsDeletionStatus.idle,
    this.deletionPreview,
    this.deletionError,
  });

  final SettingsStatus status;
  final CaregiverModel? caregiver;
  final Map<String, bool> notifications;
  final String? errorMessage;

  /// Estágio atual do fluxo de exclusão da conta.
  final SettingsDeletionStatus deletionStatus;

  /// Prévia resolvida do impacto da exclusão (null até [SettingsDeletionStatus.ready]).
  final DeleteAccountPreview? deletionPreview;

  /// Mensagem de erro específica do fluxo de exclusão, em PT-BR.
  final String? deletionError;

  SettingsState copyWith({
    SettingsStatus? status,
    CaregiverModel? caregiver,
    Map<String, bool>? notifications,
    String? errorMessage,
    SettingsDeletionStatus? deletionStatus,
    DeleteAccountPreview? deletionPreview,
    String? deletionError,
  }) {
    return SettingsState(
      status: status ?? this.status,
      caregiver: caregiver ?? this.caregiver,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
      deletionStatus: deletionStatus ?? this.deletionStatus,
      deletionPreview: deletionPreview ?? this.deletionPreview,
      deletionError: deletionError ?? this.deletionError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        caregiver,
        notifications,
        errorMessage,
        deletionStatus,
        deletionPreview,
        deletionError,
      ];
}
