/*
 * CareHub Plus — SOS / BLoC
 *
 * Coordena o pedido de ajuda à rede de apoio. Guarda a máquina de estados do
 * fluxo (montar o pedido → alerta enviado → chamado aceito), a contagem
 * regressiva de cancelamento e as escolhas da cuidadora. Nenhuma tela decide
 * transição de etapa: elas só desenham a etapa atual e avisam a intenção.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../services/selected_profile_service.dart';
import '../../../home/data/models/care_recipient_model.dart';
import '../../../network/data/models/network_member_model.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../data/repositories/sos_repository.dart';
import '../../domain/entities/sos_acceptance_entity.dart';
import '../../domain/entities/sos_alert_snapshot_entity.dart';
import '../../domain/entities/sos_help_request_entity.dart';

part 'sos_event.dart';
part 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  SosBloc({required SosRepository repository})
    : _repository = repository,
      super(const SosState()) {
    on<SosLoadEvent>(_onLoad);
    on<SosProfileChangedEvent>(_onProfileChanged);
    on<SosTaskSelectedEvent>(_onTaskSelected);
    on<SosMemberToggledEvent>(_onMemberToggled);
    on<SosAlertRequestedEvent>(_onAlertRequested);
    on<SosCountdownTickedEvent>(_onCountdownTicked);
    on<SosCountdownPausedEvent>(_onCountdownPaused);
    on<SosCountdownResumedEvent>(_onCountdownResumed);
    on<SosAlertCancelledEvent>(_onAlertCancelled);
    on<SosAlertRestartedEvent>(_onAlertRestarted);
    on<SosWaitingTickedEvent>(_onWaitingTicked);
    on<SosAlertSnapshotReceivedEvent>(_onAlertSnapshotReceived);
    on<SosAlertWatchFailedEvent>(_onAlertWatchFailed);
  }

  final SosRepository _repository;

  /// Contagem regressiva da janela de cancelamento.
  Timer? _countdown;

  /// Relógio do tempo de espera por resposta, depois do envio.
  Timer? _waitingTicker;

  /// Escuta em tempo real do documento do alerta no Firestore.
  StreamSubscription<SosAlertSnapshotEntity>? _alertSubscription;

  /// Alerta em andamento.
  String? _alertId;

  @override
  Future<void> close() async {
    _countdown?.cancel();
    await _stopWaiting();
    return super.close();
  }

  Future<void> _onLoad(SosLoadEvent event, Emitter<SosState> emit) async {
    emit(state.copyWith(status: SosStatus.loading, clearErrorMessage: true));

    try {
      final photoUrl = await _repository.fetchCaregiverPhotoUrl();
      final profiles = await _repository.fetchProfiles();
      final profileId = await _resolveProfileId(
        event.careRecipientId,
        profiles,
      );
      final members = await _repository.fetchSupportNetwork(
        careRecipientId: profileId,
      );
      final isRequesterOwner = await _resolveIsRequesterOwner(profileId);
      final openTasks = profileId.isEmpty
          ? const <TaskModel>[]
          : await _repository.fetchOpenTasks(careRecipientId: profileId);
      final selectedTaskId = _resolveInitialTaskId(
        requestedTaskId: event.taskId,
        openTasks: openTasks,
      );

      if (isClosed) return;
      emit(
        state.copyWith(
          status: SosStatus.ready,
          phase: SosPhase.composing,
          caregiverPhotoUrl: photoUrl,
          profiles: profiles,
          selectedProfileId: profileId,
          members: members,
          isRequesterOwner: isRequesterOwner,
          // Em uma emergência, avisar todo mundo é o padrão: desmarcar é a
          // exceção, não a regra.
          notifiedMemberIds: members.map((member) => member.id).toSet(),
          openTasks: openTasks,
          selectedTaskId: selectedTaskId,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(status: SosStatus.failure, errorMessage: e.message));
    }
  }

  Future<void> _onProfileChanged(
    SosProfileChangedEvent event,
    Emitter<SosState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedProfileId: event.profileId,
        openTasks: const [],
        clearSelectedTask: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final openTasks = await _repository.fetchOpenTasks(
        careRecipientId: event.profileId,
      );
      final members = await _repository.fetchSupportNetwork(
        careRecipientId: event.profileId,
      );
      final isRequesterOwner = await _resolveIsRequesterOwner(event.profileId);
      final selectedTaskId = _resolveInitialTaskId(
        requestedTaskId: null,
        openTasks: openTasks,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          openTasks: openTasks,
          selectedTaskId: selectedTaskId,
          members: members,
          isRequesterOwner: isRequesterOwner,
          notifiedMemberIds: members.map((member) => member.id).toSet(),
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _onTaskSelected(SosTaskSelectedEvent event, Emitter<SosState> emit) {
    final isAlreadySelected = state.selectedTaskId == event.taskId;
    emit(
      isAlreadySelected
          ? state.copyWith(clearSelectedTask: true)
          : state.copyWith(selectedTaskId: event.taskId),
    );
  }

  void _onMemberToggled(SosMemberToggledEvent event, Emitter<SosState> emit) {
    final updated = Set<String>.of(state.notifiedMemberIds);
    // `remove` devolve false quando o id não estava marcado — então era um
    // clique para marcar.
    if (!updated.remove(event.memberId)) {
      updated.add(event.memberId);
    }
    emit(state.copyWith(notifiedMemberIds: updated));
  }

  Future<void> _onAlertRequested(
    SosAlertRequestedEvent event,
    Emitter<SosState> emit,
  ) async {
    final task = state.selectedTask;
    if (task == null || !state.canTriggerAlert) {
      emit(
        state.copyWith(
          errorMessage:
              'Escolha uma tarefa e pelo menos uma pessoa da rede de apoio.',
        ),
      );
      return;
    }

    final request = SosHelpRequestEntity(
      careRecipientId: state.selectedProfileId,
      taskId: task.id,
      taskTitle: task.title,
      notifiedMemberIds: state.notifiedMemberIds.toList(),
      notifyOwner: state.ownerWillBeNotified,
    );

    try {
      final alertId = await _repository.notifySupportNetwork(request);
      if (isClosed) return;

      _alertId = alertId;
      emit(
        state.copyWith(
          phase: SosPhase.alerting,
          secondsRemaining: SosRepository.cancellationWindow.inSeconds,
          clearAcceptance: true,
          clearErrorMessage: true,
        ),
      );
      _startCountdown();
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onCountdownTicked(
    SosCountdownTickedEvent event,
    Emitter<SosState> emit,
  ) async {
    if (state.phase != SosPhase.alerting) return;

    final remaining = state.secondsRemaining - 1;
    if (remaining > 0) {
      emit(state.copyWith(secondsRemaining: remaining));
      return;
    }

    // Janela de cancelamento encerrada: libera o WhatsApp e passa a esperar
    // a resposta real da rede de apoio.
    _countdown?.cancel();
    emit(state.copyWith(secondsRemaining: 0));

    final alertId = _alertId;
    if (alertId == null) return;

    try {
      await _repository.dispatchAlert(alertId);
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: SosPhase.waiting,
          secondsWaiting: 0,
          clearAlertSnapshot: true,
        ),
      );
      _startWaiting(alertId);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _onWaitingTicked(SosWaitingTickedEvent event, Emitter<SosState> emit) {
    if (state.phase != SosPhase.waiting || state.isWaitingOver) return;
    emit(state.copyWith(secondsWaiting: state.secondsWaiting + 1));
  }

  Future<void> _onAlertSnapshotReceived(
    SosAlertSnapshotReceivedEvent event,
    Emitter<SosState> emit,
  ) async {
    if (state.phase != SosPhase.waiting) return;
    final snapshot = event.snapshot;

    if (snapshot.isAccepted) {
      await _stopWaiting();
      _alertId = null;
      emit(
        state.copyWith(
          phase: SosPhase.accepted,
          alertSnapshot: snapshot,
          acceptance: SosAcceptanceEntity(
            memberId: snapshot.acceptedByMemberId!,
          ),
        ),
      );
      return;
    }

    if (snapshot.status == SosAlertStatus.cancelled) {
      // Cancelado fora desta tela (outro aparelho): volta ao início.
      await _stopWaiting();
      _alertId = null;
      emit(
        state.copyWith(
          phase: SosPhase.composing,
          secondsWaiting: 0,
          clearAlertSnapshot: true,
          clearAcceptance: true,
        ),
      );
      return;
    }

    emit(state.copyWith(alertSnapshot: snapshot));
    // Todos recusaram ou nada foi entregue: o relógio para, mas a escuta
    // continua — quem recusou ainda pode mudar de ideia e aceitar.
    if (state.isWaitingOver) _waitingTicker?.cancel();
  }

  void _onAlertWatchFailed(
    SosAlertWatchFailedEvent event,
    Emitter<SosState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.message));
  }

  /// Liga o relógio de espera e a escuta do alerta no Firestore.
  void _startWaiting(String alertId) {
    _waitingTicker?.cancel();
    _waitingTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const SosWaitingTickedEvent()),
    );

    _alertSubscription?.cancel();
    _alertSubscription = _repository
        .watchAlert(alertId)
        .listen(
          (snapshot) => add(SosAlertSnapshotReceivedEvent(snapshot: snapshot)),
          onError: (Object error) => add(
            SosAlertWatchFailedEvent(
              message: error is AppException
                  ? error.message
                  : 'Não foi possível acompanhar as respostas da rede de '
                        'apoio.',
            ),
          ),
        );
  }

  /// Desliga o relógio e a escuta. Sem isso, a escuta continuaria consumindo
  /// leituras do Firestore depois de sair da tela.
  Future<void> _stopWaiting() async {
    _waitingTicker?.cancel();
    _waitingTicker = null;
    await _alertSubscription?.cancel();
    _alertSubscription = null;
  }

  /// Enquanto a confirmação de cancelamento está aberta, o tempo não corre —
  /// senão a rede poderia "aceitar" o chamado por baixo do modal.
  void _onCountdownPaused(
    SosCountdownPausedEvent event,
    Emitter<SosState> emit,
  ) {
    _countdown?.cancel();
  }

  void _onCountdownResumed(
    SosCountdownResumedEvent event,
    Emitter<SosState> emit,
  ) {
    if (state.phase != SosPhase.alerting) return;
    _startCountdown();
  }

  Future<void> _onAlertCancelled(
    SosAlertCancelledEvent event,
    Emitter<SosState> emit,
  ) async {
    _countdown?.cancel();
    await _stopWaiting();
    final alertId = _alertId;
    _alertId = null;

    emit(
      state.copyWith(
        phase: SosPhase.composing,
        secondsRemaining: 0,
        secondsWaiting: 0,
        clearAlertSnapshot: true,
        clearAcceptance: true,
        clearErrorMessage: true,
      ),
    );

    if (alertId == null) return;
    try {
      await _repository.cancelAlert(alertId);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onAlertRestarted(
    SosAlertRestartedEvent event,
    Emitter<SosState> emit,
  ) async {
    _countdown?.cancel();
    await _stopWaiting();
    _alertId = null;

    emit(
      state.copyWith(
        phase: SosPhase.composing,
        secondsRemaining: 0,
        secondsWaiting: 0,
        clearAlertSnapshot: true,
        selectedTaskId: _resolveInitialTaskId(
          requestedTaskId: null,
          openTasks: state.openTasks,
        ),
        clearAcceptance: true,
        clearErrorMessage: true,
      ),
    );
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const SosCountdownTickedEvent()),
    );
  }

  /// Respeita a tarefa recebida pela rota quando ela ainda está em aberto. Sem
  /// pré-seleção, escolhe primeiro a mais atrasada; sem atrasos, a próxima
  /// tarefa com horário mais cedo.
  String? _resolveInitialTaskId({
    required String? requestedTaskId,
    required List<TaskModel> openTasks,
  }) {
    if (openTasks.isEmpty) return null;

    if (requestedTaskId != null) {
      for (final task in openTasks) {
        if (task.id == requestedTaskId) return task.id;
      }
    }

    final now = DateTime.now();
    final overdueTasks = openTasks
        .where((task) => task.scheduledTime.isBefore(now))
        .toList();
    final priorityTasks = overdueTasks.isEmpty ? openTasks : overdueTasks;

    var priorityTask = priorityTasks.first;
    for (final task in priorityTasks.skip(1)) {
      if (task.scheduledTime.isBefore(priorityTask.scheduledTime)) {
        priorityTask = task;
      }
    }
    return priorityTask.id;
  }

  /// Descobre se quem está pedindo é o dono do perfil. Numa falha de leitura,
  /// assume `true` (o comportamento antigo: exigir a rede de apoio), para não
  /// liberar um pedido por engano.
  Future<bool> _resolveIsRequesterOwner(String profileId) async {
    if (profileId.isEmpty) return true;
    try {
      return await _repository.isCurrentUserOwnerOf(profileId);
    } on AppException {
      return true;
    }
  }

  /// Perfil que deve abrir selecionado: o pedido da rota, quando existe, ou o
  /// primeiro perfil cadastrado.
  /// Resolve o perfil a exibir: id recebido por navegação, depois o perfil
  /// salvo pela seleção do usuário e, por fim, o primeiro da lista. Evita que
  /// o SOS "troque" de assistido quando aberto sem um id explícito.
  Future<String> _resolveProfileId(
    String? requestedProfileId,
    List<CareRecipientModel> profiles,
  ) async {
    bool existsInList(String id) => profiles.any((p) => p.id == id);

    if (requestedProfileId != null &&
        requestedProfileId.isNotEmpty &&
        existsInList(requestedProfileId)) {
      return requestedProfileId;
    }

    try {
      final service = await SelectedProfileService.create();
      final savedId = service.getSelectedProfileId();
      if (savedId != null && existsInList(savedId)) {
        return savedId;
      }
    } catch (_) {
      // Falha ao ler a seleção não impede o carregamento do SOS.
    }

    return profiles.isNotEmpty ? profiles.first.id : '';
  }
}
