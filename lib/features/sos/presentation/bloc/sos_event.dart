part of 'sos_bloc.dart';

abstract class SosEvent extends Equatable {
  const SosEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega perfis, rede de apoio e tarefas em aberto da tela.
class SosLoadEvent extends SosEvent {
  const SosLoadEvent({this.careRecipientId, this.taskId});

  /// Perfil que deve vir selecionado (vem da rota, quando informado).
  final String? careRecipientId;

  /// Tarefa que deve vir selecionada (vem da rota, quando informada).
  final String? taskId;

  @override
  List<Object?> get props => [careRecipientId, taskId];
}

/// Troca o perfil cuidado e recarrega as tarefas em aberto dele.
class SosProfileChangedEvent extends SosEvent {
  const SosProfileChangedEvent({required this.profileId});

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

/// Escolhe (ou desmarca) a tarefa que motiva o pedido de ajuda.
class SosTaskSelectedEvent extends SosEvent {
  const SosTaskSelectedEvent({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Marca ou desmarca uma pessoa da rede de apoio para ser avisada.
class SosMemberToggledEvent extends SosEvent {
  const SosMemberToggledEvent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

/// Dispara o alerta e abre a janela de cancelamento.
class SosAlertRequestedEvent extends SosEvent {
  const SosAlertRequestedEvent();
}

/// Batida de um segundo da contagem regressiva. Evento interno do BLoC.
class SosCountdownTickedEvent extends SosEvent {
  const SosCountdownTickedEvent();
}

/// Segura a contagem regressiva enquanto a cuidadora decide se cancela.
class SosCountdownPausedEvent extends SosEvent {
  const SosCountdownPausedEvent();
}

/// Retoma a contagem regressiva quando a cuidadora decide manter o alerta.
class SosCountdownResumedEvent extends SosEvent {
  const SosCountdownResumedEvent();
}

/// Cancela o alerta em andamento.
class SosAlertCancelledEvent extends SosEvent {
  const SosAlertCancelledEvent();
}

/// Encerra o atendimento aceito e volta ao início da tela.
class SosAlertRestartedEvent extends SosEvent {
  const SosAlertRestartedEvent();
}
