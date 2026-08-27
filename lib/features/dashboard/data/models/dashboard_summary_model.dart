/*
 * CareHub Plus — Data / Dashboard Summary Model
 *
 * Agrega todas as métricas e contexto necessários para o resumo diário
 * exibido na tela de Dashboard para o perfil cuidado selecionado.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'next_task_preview_model.dart';
import 'suggestion_model.dart';

/// Resumo diário do Dashboard para um perfil cuidado específico.
class DashboardSummaryModel extends Equatable {
  const DashboardSummaryModel({
    required this.monitoredProfilesCount,
    required this.pendingTasksCount,
    required this.supportNetworkCount,
    required this.unreadChatsCount,
    required this.completedTasksTodayCount,
    required this.totalTasksTodayCount,
    required this.overdueTasksCount,
    this.nextTask,
    this.suggestions = const [],
  });

  // ── Contagens gerais ──────────────────────────────────────────────────────

  /// Total de perfis cuidados cadastrados pelo cuidador (não filtra por perfil).
  final int monitoredProfilesCount;

  /// Tarefas pendentes (não concluídas) do perfil ativo — todos os dias.
  final int pendingTasksCount;

  /// Membros na rede de apoio do perfil ativo.
  final int supportNetworkCount;

  /// Salas de chat com mensagens não lidas do perfil ativo.
  final int unreadChatsCount;

  // ── Progresso do dia ──────────────────────────────────────────────────────

  /// Tarefas concluídas hoje (completedAt >= início do dia local).
  final int completedTasksTodayCount;

  /// Total de tarefas agendadas para hoje (scheduledTime no dia atual).
  final int totalTasksTodayCount;

  /// Tarefas atrasadas: pendentes com scheduledTime anterior a agora.
  final int overdueTasksCount;

  /// Próxima tarefa pendente mais próxima em horário. Nulo quando não há
  /// tarefas pendentes para o perfil.
  final NextTaskPreviewModel? nextTask;

  // ── Sugestões da Cora ─────────────────────────────────────────────────────

  /// Sugestões proativas geradas pela IA. Lista vazia é estado válido.
  final List<SuggestionModel> suggestions;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Progresso do dia como fração [0.0, 1.0].
  /// Retorna 0.0 quando não há tarefas hoje para evitar divisão por zero.
  double get dailyProgress => totalTasksTodayCount == 0
      ? 0.0
      : (completedTasksTodayCount / totalTasksTodayCount).clamp(0.0, 1.0);

  /// Verdadeiro quando todas as tarefas de hoje estão concluídas e há pelo
  /// menos uma — usado para exibir a mensagem de parabenização.
  bool get allTasksDoneToday =>
      totalTasksTodayCount > 0 &&
      completedTasksTodayCount >= totalTasksTodayCount;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      monitoredProfilesCount: json['monitoredProfilesCount'] as int? ?? 0,
      pendingTasksCount: json['pendingTasksCount'] as int? ?? 0,
      supportNetworkCount: json['supportNetworkCount'] as int? ?? 0,
      unreadChatsCount: json['unreadChatsCount'] as int? ?? 0,
      completedTasksTodayCount:
          json['completedTasksTodayCount'] as int? ?? 0,
      totalTasksTodayCount: json['totalTasksTodayCount'] as int? ?? 0,
      overdueTasksCount: json['overdueTasksCount'] as int? ?? 0,
      nextTask: json['nextTask'] != null
          ? NextTaskPreviewModel.fromJson(
              json['nextTask'] as Map<String, dynamic>)
          : null,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monitoredProfilesCount': monitoredProfilesCount,
      'pendingTasksCount': pendingTasksCount,
      'supportNetworkCount': supportNetworkCount,
      'unreadChatsCount': unreadChatsCount,
      'completedTasksTodayCount': completedTasksTodayCount,
      'totalTasksTodayCount': totalTasksTodayCount,
      'overdueTasksCount': overdueTasksCount,
      'nextTask': nextTask == null
          ? null
          : {
              'id': nextTask!.id,
              'title': nextTask!.title,
              'scheduledTime': nextTask!.scheduledTime.toIso8601String(),
              'categoryId': nextTask!.categoryId,
              'assignedToName': nextTask!.assignedToName,
            },
      'suggestions': suggestions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        monitoredProfilesCount,
        pendingTasksCount,
        supportNetworkCount,
        unreadChatsCount,
        completedTasksTodayCount,
        totalTasksTodayCount,
        overdueTasksCount,
        nextTask,
        suggestions,
      ];
}
