/*
 * CareHub Plus — Dados SOS / Repositório de pedidos de ajuda
 *
 * Porta de entrada única de dados da tela de SOS. A tela precisa juntar coisas
 * que vivem em três features diferentes (perfis cuidados, tarefas e rede de
 * apoio) e ainda disparar o alerta. Em vez de injetar quatro dependências no
 * BLoC, este repositório funciona como uma fachada (padrão Facade): o BLoC
 * conhece só ele, e os testes precisam simular só ele.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../services/cloud_functions_service.dart';
import '../../../assistants/data/repositories/caregiver_avatar_repository.dart';
import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../../../network/data/models/network_member_model.dart';
import '../../../network/data/repositories/network_repository.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';
import '../../domain/entities/sos_alert_detail_entity.dart';
import '../../domain/entities/sos_alert_snapshot_entity.dart';
import '../../domain/entities/sos_help_request_entity.dart';

/// Fachada de dados do SOS: leitura da tela e ciclo de vida do alerta.
class SosRepository {
  SosRepository({
    HomeRepository? homeRepository,
    TasksRepository? tasksRepository,
    NetworkRepository? networkRepository,
    CaregiverAvatarRepository? caregiverAvatarRepository,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CallableClient? client,
  }) : _homeRepository = homeRepository ?? HomeRepository(),
       _tasksRepository = tasksRepository ?? TasksRepository(),
       _networkRepository = networkRepository ?? NetworkRepository(),
       _caregiverAvatarRepository =
           caregiverAvatarRepository ?? CaregiverAvatarRepository(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? CloudFunctionsService();

  final HomeRepository _homeRepository;
  final TasksRepository _tasksRepository;
  final NetworkRepository _networkRepository;
  final CaregiverAvatarRepository _caregiverAvatarRepository;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CallableClient _client;

  /// Coleção observada pela Cloud Function que avisa a rede pelo WhatsApp.
  static const String _alertsCollection = 'sos_alerts';

  /// Ciclo de vida do alerta. O backend só envia o WhatsApp quando o status
  /// vira [_statusDispatched]; um alerta cancelado antes disso não gera
  /// mensagem.
  static const String _statusPending = 'pending';
  static const String _statusDispatched = 'dispatched';
  static const String _statusAccepted = 'accepted';
  static const String _statusCancelled = 'cancelled';

  /// Tempo que a cuidadora tem para cancelar o alerta antes de o aviso sair
  /// pelo WhatsApp. Vive aqui, e não na interface, porque é regra do fluxo.
  static const Duration cancellationWindow = Duration(seconds: 10);

  /// Foto do cuidador autenticado para o cabeçalho. `null` quando a conta não
  /// tem foto — nesse caso o `AppHeader` mostra o avatar genérico.
  Future<String?> fetchCaregiverPhotoUrl() =>
      _caregiverAvatarRepository.fetchPhotoUrl();

  /// Perfis cuidados disponíveis para o filtro do topo da tela.
  Future<List<CareRecipientModel>> fetchProfiles() =>
      _homeRepository.fetchCareRecipients();

  /// Membros da rede de apoio que podem ser acionados.
  Future<List<NetworkMemberModel>> fetchSupportNetwork({
    String? careRecipientId,
  }) => _networkRepository.fetchMembers(careRecipientId: careRecipientId);

  /// Tarefas ainda em aberto do perfil selecionado — só elas fazem sentido
  /// como motivo de um pedido de ajuda.
  Future<List<TaskModel>> fetchOpenTasks({
    required String careRecipientId,
  }) async {
    final tasks = await _tasksRepository.fetchTasks(
      careRecipientId: careRecipientId,
    );
    return tasks.where((task) => !task.isCompleted).toList();
  }

  /// Registra o pedido de ajuda em `sos_alerts` como "pending" e devolve o id
  /// do alerta criado.
  ///
  /// O aviso pelo WhatsApp só sai quando a janela de cancelamento termina
  /// (ver [dispatchAlert]), para que um cancelamento não gere mensagem.
  Future<String> notifySupportNetwork(SosHelpRequestEntity request) async {
    if (!request.isValid) {
      throw const AppException(
        'Escolha uma tarefa e pelo menos uma pessoa da rede de apoio.',
      );
    }

    final alertId = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    final uid = _currentUserId();

    try {
      // O alerta pertence à dona do assistido. Num perfil compartilhado,
      // `requestedByUid` registra quem pediu (as regras conferem os dois).
      final owner = await _ownerOf(request.careRecipientId) ?? uid;
      await _firestore.collection(_alertsCollection).doc(alertId).set({
        'id': alertId,
        'caregiverId': owner,
        'requestedByUid': uid,
        'requestedBy': 'uid:$uid',
        if (owner != uid) 'requestedByName': _auth.currentUser?.displayName,
        'careRecipientId': request.careRecipientId,
        'taskId': request.taskId,
        'taskTitle': request.taskTitle,
        'notifiedMemberIds': request.notifiedMemberIds,
        'status': _statusPending,
        'createdAt': now,
        'updatedAt': now,
      });
    } on FirebaseException catch (error) {
      throw AppException(
        'Não foi possível registrar o pedido de ajuda. Tente novamente.',
        code: error.code,
      );
    }

    return alertId;
  }

  /// Chamado quando a janela de cancelamento termina: muda o alerta para
  /// "dispatched", o que faz o backend enviar o WhatsApp para a rede.
  Future<void> dispatchAlert(String alertId) async {
    if (alertId.isEmpty) {
      throw const AppException('Não há alerta em andamento para enviar.');
    }
    await _updateAlertStatus(alertId, _statusDispatched);
  }

  /// Acompanha o alerta em tempo real. Emite a cada resposta gravada pelo
  /// webhook do WhatsApp ("Estou indo" / "Não posso") e quando o backend
  /// termina o envio. Quem escuta deve cancelar a inscrição ao sair da tela.
  Stream<SosAlertSnapshotEntity> watchAlert(String alertId) {
    return _firestore
        .collection(_alertsCollection)
        .doc(alertId)
        .snapshots()
        .where((document) => document.exists)
        .map((document) => _toSnapshot(document.data() ?? const {}))
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw AppException(
              'Não foi possível acompanhar as respostas da rede de apoio.',
              code: error.code,
            );
          }
          throw error;
        });
  }

  /// Cancela um alerta em andamento. Dentro da janela de cancelamento, impede
  /// o envio pelo WhatsApp; depois dela, registra que o pedido foi encerrado.
  Future<void> cancelAlert(String alertId) async {
    if (alertId.isEmpty) {
      throw const AppException('Não há alerta em andamento para cancelar.');
    }
    await _updateAlertStatus(alertId, _statusCancelled);
  }

  /// Lê uma única vez os detalhes do alerta [alertId] para a tela aberta pela
  /// notificação de SOS. Diferente de [watchAlert], não acompanha em tempo
  /// real: só busca quem pediu, qual tarefa e a etapa atual do pedido.
  Future<SosAlertDetailEntity> fetchAlertDetail(String alertId) async {
    try {
      final document = await _firestore
          .collection(_alertsCollection)
          .doc(alertId)
          .get();
      final data = document.data();
      if (!document.exists || data == null) {
        throw const AppException('Este pedido de ajuda não foi encontrado.');
      }

      final status = switch (data['status']) {
        _statusPending => SosAlertStatus.pending,
        _statusDispatched => SosAlertStatus.dispatched,
        _statusAccepted => SosAlertStatus.accepted,
        _statusCancelled => SosAlertStatus.cancelled,
        _ => SosAlertStatus.unknown,
      };

      final createdAtRaw = data['createdAt'];
      final createdAt = createdAtRaw is String
          ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
          : DateTime.now();

      final notified = data['notifiedMemberIds'];
      final notifiedMemberIds = notified is List
          ? notified.whereType<String>().toList()
          : const <String>[];

      final requestedByName = data['requestedByName'];
      final taskId = data['taskId'];
      final taskTitle = data['taskTitle'];
      final acceptedBy = data['acceptedByMemberId'];

      return SosAlertDetailEntity(
        alertId: alertId,
        requestedByUid: (data['requestedByUid'] as String?) ?? '',
        requestedByName: requestedByName is String && requestedByName.isNotEmpty
            ? requestedByName
            : null,
        careRecipientId: (data['careRecipientId'] as String?) ?? '',
        taskId: taskId is String && taskId.isNotEmpty ? taskId : null,
        taskTitle: taskTitle is String && taskTitle.isNotEmpty
            ? taskTitle
            : null,
        status: status,
        createdAt: createdAt,
        acceptedByMemberId: acceptedBy is String && acceptedBy.isNotEmpty
            ? acceptedBy
            : null,
        notifiedMemberIds: notifiedMemberIds,
      );
    } on FirebaseException catch (error) {
      throw AppException(
        'Não foi possível abrir o pedido de ajuda. Tente novamente.',
        code: error.code,
      );
    }
  }

  /// A pessoa acionada aceita o pedido de ajuda. O backend (callable com
  /// Admin SDK) resolve quem é o membro pelo login, registra o aceite e avisa
  /// quem pediu. O app passa apenas o [alertId]; a identificação do membro
  /// acontece no servidor.
  Future<void> acceptAlert(String alertId) async {
    await _client.call('acceptSosAlert', {'alertId': alertId});
  }

  /// Converte o documento do Firestore no retrato de domínio. Campos ausentes
  /// ou com tipo inesperado viram "sem informação" em vez de erro.
  SosAlertSnapshotEntity _toSnapshot(Map<String, dynamic> data) {
    final status = switch (data['status']) {
      _statusPending => SosAlertStatus.pending,
      _statusDispatched => SosAlertStatus.dispatched,
      _statusAccepted => SosAlertStatus.accepted,
      _statusCancelled => SosAlertStatus.cancelled,
      _ => SosAlertStatus.unknown,
    };

    final responses = <String, SosMemberResponse>{};
    final rawResponses = data['responses'];
    if (rawResponses is Map) {
      rawResponses.forEach((memberId, value) {
        final response = switch (value) {
          'accepted' => SosMemberResponse.accepted,
          'declined' => SosMemberResponse.declined,
          _ => null,
        };
        if (memberId is String && response != null) {
          responses[memberId] = response;
        }
      });
    }

    final summary = data['whatsappSummary'];
    final acceptedBy = data['acceptedByMemberId'];

    return SosAlertSnapshotEntity(
      status: status,
      acceptedByMemberId: acceptedBy is String && acceptedBy.isNotEmpty
          ? acceptedBy
          : null,
      responses: responses,
      whatsappSent: summary is Map ? (summary['sent'] as num?)?.toInt() : null,
      whatsappFailed: summary is Map
          ? (summary['failed'] as num?)?.toInt()
          : null,
    );
  }

  Future<void> _updateAlertStatus(String alertId, String status) async {
    try {
      await _firestore.collection(_alertsCollection).doc(alertId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (error) {
      throw AppException(
        'Não foi possível atualizar o pedido de ajuda. Tente novamente.',
        code: error.code,
      );
    }
  }

  Future<String?> _ownerOf(String careRecipientId) async {
    if (careRecipientId.isEmpty) return null;
    final recipient = await _firestore
        .collection('care_recipients')
        .doc(careRecipientId)
        .get();
    return recipient.data()?['caregiverId'] as String?;
  }

  String _currentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        'Usuário não autenticado. Faça login novamente.',
      );
    }
    return user.uid;
  }
}
