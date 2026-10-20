part of 'sos_bloc.dart';

/// Situação do carregamento dos dados da tela.
enum SosStatus { initial, loading, ready, failure }

/// Etapa do pedido de ajuda. É a máquina de estados do fluxo: cada etapa
/// desenha uma tela diferente, e só o BLoC decide a transição.
enum SosPhase {
  /// Montando o pedido: escolher a tarefa e quem avisar.
  composing,

  /// Alerta criado, dentro da janela de cancelamento (o WhatsApp ainda não
  /// saiu).
  alerting,

  /// WhatsApp enviado: aguardando alguém da rede responder.
  waiting,

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
    this.isRequesterOwner = true,
    this.secondsRemaining = 0,
    this.secondsWaiting = 0,
    this.alertSnapshot,
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

  /// Se quem está pedindo ajuda é o próprio dono do perfil. Quando `false`, o
  /// dono é avisado como destinatário especial, então o pedido vale mesmo sem
  /// membros marcados. Padrão `true` (seguro: exige rede até sabermos o dono).
  final bool isRequesterOwner;

  final int secondsRemaining;

  /// Há quanto tempo o aviso saiu sem ninguém aceitar (etapa `waiting`).
  final int secondsWaiting;

  /// Última situação do alerta lida do Firestore (respostas e envio).
  final SosAlertSnapshotEntity? alertSnapshot;
  final SosAcceptanceEntity? acceptance;
  final String? errorMessage;

  /// Todos os avisados responderam "Não posso".
  bool get everyoneDeclined {
    final snapshot = alertSnapshot;
    if (snapshot == null || notifiedMemberIds.isEmpty) return false;
    return notifiedMemberIds.every(snapshot.hasDeclined);
  }

  /// Ninguém vai responder: todos recusaram ou nenhum aviso foi entregue.
  bool get isWaitingOver =>
      everyoneDeclined || (alertSnapshot?.deliveryFailedForAll ?? false);

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

  /// Se o dono será avisado como destinatário especial deste pedido — ou seja,
  /// quem está pedindo não é o dono do perfil.
  bool get ownerWillBeNotified => !isRequesterOwner;

  /// O botão de SOS libera com uma tarefa escolhida e alguém para avisar: um
  /// membro marcado ou o dono do perfil (quando quem pede não é o dono).
  bool get canTriggerAlert =>
      selectedTask != null &&
      (notifiedMemberIds.isNotEmpty || ownerWillBeNotified);

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
    bool? isRequesterOwner,
    int? secondsRemaining,
    int? secondsWaiting,
    SosAlertSnapshotEntity? alertSnapshot,
    bool clearAlertSnapshot = false,
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
      isRequesterOwner: isRequesterOwner ?? this.isRequesterOwner,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      secondsWaiting: secondsWaiting ?? this.secondsWaiting,
      alertSnapshot: clearAlertSnapshot
          ? null
          : alertSnapshot ?? this.alertSnapshot,
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
        isRequesterOwner,
        secondsRemaining,
        secondsWaiting,
        alertSnapshot,
        acceptance,
        errorMessage,
      ];
}
