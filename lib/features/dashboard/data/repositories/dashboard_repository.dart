/*
 * CareHub Plus — Data / Dashboard Repository
 *
 * Agrega dados de múltiplas fontes do Firestore para montar o resumo diário
 * exibido no Dashboard. Todas as queries são independentes e executadas em
 * paralelo via Future.wait para minimizar a latência percebida.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/models/caregiver_model.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../models/dashboard_summary_model.dart';
import '../models/next_task_preview_model.dart';

/// Repositório do Dashboard.
///
/// Responsável por agregar contagens e contexto real do Firestore.
/// Não produz nem armazena sugestões da Cora — isso é domínio da
/// feature `cora/`, que futuramente pode expor um método próprio.
class DashboardRepository {
  DashboardRepository({
    HomeRepository? homeRepository,
    FirebaseFirestore? firestore,
  })  : _homeRepository = homeRepository ?? HomeRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final HomeRepository _homeRepository;
  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Delegações ao HomeRepository
  // ---------------------------------------------------------------------------

  /// Retorna o Cuidador autenticado.
  Future<CaregiverModel> fetchCaregiver() {
    return _homeRepository.fetchCaregiver();
  }

  /// Retorna todos os perfis cuidados gerenciados por este Cuidador.
  Future<List<CareRecipientModel>> fetchCareRecipients() {
    return _homeRepository.fetchCareRecipients();
  }

  // ---------------------------------------------------------------------------
  // Resumo do Dashboard
  // ---------------------------------------------------------------------------

  /// Monta o [DashboardSummaryModel] com dados reais do Firestore.
  ///
  /// Todas as queries são disparadas em paralelo via [Future.wait].
  /// Se qualquer query falhar individualmente, o valor correspondente é
  /// zerado e o dashboard ainda exibe as demais informações — tolerância a
  /// falha parcial deliberada.
  Future<DashboardSummaryModel> fetchDashboardSummary({
    required String profileId,
    required int monitoredProfilesCount,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final results = await Future.wait([
      _fetchPendingTasksCount(profileId),           // [0]
      _fetchSupportNetworkCount(profileId),          // [1]
      _fetchUnreadChatsCount(profileId),             // [2]
      _fetchCompletedTasksTodayCount(profileId, todayStart, todayEnd), // [3]
      _fetchTotalTasksTodayCount(profileId, todayStart, todayEnd),     // [4]
      _fetchOverdueTasksCount(profileId, now),       // [5]
    ]);

    final nextTask = await _fetchNextTask(profileId, now);

    return DashboardSummaryModel(
      monitoredProfilesCount: monitoredProfilesCount,
      pendingTasksCount: results[0],
      supportNetworkCount: results[1],
      unreadChatsCount: results[2],
      completedTasksTodayCount: results[3],
      totalTasksTodayCount: results[4],
      overdueTasksCount: results[5],
      nextTask: nextTask,
      suggestions: const [],
    );
  }

  // ---------------------------------------------------------------------------
  // Queries privadas
  // ---------------------------------------------------------------------------

  /// Tarefas pendentes (não concluídas) — todos os dias.
  Future<int> _fetchPendingTasksCount(String profileId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('careRecipientId', isEqualTo: profileId)
          .where('isCompleted', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Membros da rede de apoio vinculados ao perfil.
  Future<int> _fetchSupportNetworkCount(String profileId) async {
    try {
      final snapshot = await _firestore
          .collection('network_members')
          .where('careRecipientId', isEqualTo: profileId)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Salas de chat com mensagens não lidas para o perfil.
  Future<int> _fetchUnreadChatsCount(String profileId) async {
    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .where('careRecipientId', isEqualTo: profileId)
          .where('unreadCount', isGreaterThan: 0)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Tarefas concluídas hoje (completedAt entre início e fim do dia local).
  Future<int> _fetchCompletedTasksTodayCount(
    String profileId,
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('careRecipientId', isEqualTo: profileId)
          .where('isCompleted', isEqualTo: true)
          .where('completedAt',
              isGreaterThanOrEqualTo: todayStart.toIso8601String())
          .where('completedAt', isLessThan: todayEnd.toIso8601String())
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Tarefas agendadas para hoje (scheduledTime entre início e fim do dia).
  Future<int> _fetchTotalTasksTodayCount(
    String profileId,
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('careRecipientId', isEqualTo: profileId)
          .where('scheduledTime',
              isGreaterThanOrEqualTo: todayStart.toIso8601String())
          .where('scheduledTime', isLessThan: todayEnd.toIso8601String())
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Tarefas atrasadas: pendentes com scheduledTime antes de agora.
  Future<int> _fetchOverdueTasksCount(String profileId, DateTime now) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('careRecipientId', isEqualTo: profileId)
          .where('isCompleted', isEqualTo: false)
          .where('scheduledTime', isLessThan: now.toIso8601String())
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Próxima tarefa pendente mais próxima em horário a partir de agora.
  /// Retorna null quando não há tarefas pendentes.
  Future<NextTaskPreviewModel?> _fetchNextTask(
    String profileId,
    DateTime now,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('careRecipientId', isEqualTo: profileId)
          .where('isCompleted', isEqualTo: false)
          .where('scheduledTime',
              isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('scheduledTime')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return NextTaskPreviewModel.fromJson(snapshot.docs.first.data());
    } catch (_) {
      return null;
    }
  }
}
