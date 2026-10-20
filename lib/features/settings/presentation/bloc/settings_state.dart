part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, success, failure }

/// Estágio do fluxo de exclusão da conta (independente de [SettingsStatus]).
enum SettingsDeletionStatus { idle, resolving, ready, deleting, deleted, failure }

/// Estágio do salvamento das preferências de alerta de SOS do dono
/// (independente de [SettingsStatus]).
enum SettingsSosSaveStatus { idle, saving, saved, failure }

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
    this.sosPhone = '',
    this.sosAlertChannel = AlertChannel.app,
    this.sosSaveStatus = SettingsSosSaveStatus.idle,
    this.errorMessage,
    this.deletionStatus = SettingsDeletionStatus.idle,
    this.deletionPreview,
    this.deletionError,
  });

  final SettingsStatus status;
  final CaregiverModel? caregiver;
  final Map<String, bool> notifications;

  /// Telefone de WhatsApp do dono para SOS, editável na seção "Alertas de SOS".
  final String sosPhone;

  /// Canal de alerta de SOS escolhido pelo dono ([AlertChannel.app] por
  /// padrão; [AlertChannel.whatsapp] quando ele ativa o WhatsApp).
  final AlertChannel sosAlertChannel;

  /// Estágio atual do salvamento das preferências de SOS.
  final SettingsSosSaveStatus sosSaveStatus;

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
    String? sosPhone,
    AlertChannel? sosAlertChannel,
    SettingsSosSaveStatus? sosSaveStatus,
    String? errorMessage,
    SettingsDeletionStatus? deletionStatus,
    DeleteAccountPreview? deletionPreview,
    String? deletionError,
  }) {
    return SettingsState(
      status: status ?? this.status,
      caregiver: caregiver ?? this.caregiver,
      notifications: notifications ?? this.notifications,
      sosPhone: sosPhone ?? this.sosPhone,
      sosAlertChannel: sosAlertChannel ?? this.sosAlertChannel,
      sosSaveStatus: sosSaveStatus ?? this.sosSaveStatus,
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
        sosPhone,
        sosAlertChannel,
        sosSaveStatus,
        errorMessage,
        deletionStatus,
        deletionPreview,
        deletionError,
      ];
}
