part of 'sos_bloc.dart';

/// Situação do carregamento dos dados da tela.
enum SosStatus { initial, loading, ready, failure }

/// Etapa do pedido de ajuda. É a máquina de estados do fluxo: cada etapa
/// desenha uma tela diferente, e só o BLoC decide a transição.
enum SosPhase {
  /// Montando o pedido: escolher a tarefa e quem avisar.
  composing,

  /// Alerta enviado, aguardando resposta dentro da janela de cancelamento.
  alerting,

  /// Alguém da rede de apoio aceitou o chamado.
  accepted,
}

class SosState extends Equatable {
  const SosState({
    this.status = SosStatus.initial,
    this.phase = SosPhase.composing,
    this.caregiverPhotoUrl,
    this.profiles = const [],
    this.selectedProfileId = '',
    this.openTasks = const [],
    this.selectedTaskId,
    this.members = const [],
    this.notifiedMemberIds = const {},
    this.secondsRemaining = 0,
    this.acceptance,
    this.errorMessage,
  });

  final SosStatus status;
  final SosPhase phase;
  final String? caregiverPhotoUrl;
  final List<CareRecipientModel> profiles;
  final String selectedProfileId;
  final List<TaskModel> openTasks;
  final String? selectedTaskId;
  final List<NetworkMemberModel> members;
  final Set<String> notifiedMemberIds;
  final int secondsRemaining;
  final SosAcceptanceEntity? acceptance;
  final String? errorMessage;

  /// Tarefa escolhida, ou `null` quando nenhuma está selecionada (ou quando a
  /// tarefa pré-selecionada não pertence ao perfil atual).
  TaskModel? get selectedTask {
    if (selectedTaskId == null) return null;
    for (final task in openTasks) {
      if (task.id == selectedTaskId) return task;
    }
    return null;
  }

  /// Pessoas marcadas para receber o alerta, na ordem da rede de apoio.
  List<NetworkMemberModel> get notifiedMembers => members
      .where((member) => notifiedMemberIds.contains(member.id))
      .toList();

  /// Membro que aceitou o chamado, resolvido a partir do aceite.
  NetworkMemberModel? get acceptedMember {
    final memberId = acceptance?.memberId;
    if (memberId == null) return null;
    for (final member in members) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  /// O botão de SOS só libera com tarefa escolhida e alguém para avisar.
  bool get canTriggerAlert => selectedTask != null && notifiedMemberIds.isNotEmpty;

  SosState copyWith({
    SosStatus? status,
    SosPhase? phase,
    String? caregiverPhotoUrl,
    List<CareRecipientModel>? profiles,
    String? selectedProfileId,
    List<TaskModel>? openTasks,
    String? selectedTaskId,
    bool clearSelectedTask = false,
    List<NetworkMemberModel>? members,
    Set<String>? notifiedMemberIds,
    int? secondsRemaining,
    SosAcceptanceEntity? acceptance,
    bool clearAcceptance = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SosState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      caregiverPhotoUrl: caregiverPhotoUrl ?? this.caregiverPhotoUrl,
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      openTasks: openTasks ?? this.openTasks,
      selectedTaskId:
          clearSelectedTask ? null : selectedTaskId ?? this.selectedTaskId,
      members: members ?? this.members,
      notifiedMemberIds: notifiedMemberIds ?? this.notifiedMemberIds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      acceptance: clearAcceptance ? null : acceptance ?? this.acceptance,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        phase,
        caregiverPhotoUrl,
        profiles,
        selectedProfileId,
        openTasks,
        selectedTaskId,
        members,
        notifiedMemberIds,
        secondsRemaining,
        acceptance,
        errorMessage,
      ];
}
