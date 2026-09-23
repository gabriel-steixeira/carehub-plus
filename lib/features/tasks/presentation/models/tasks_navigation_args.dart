/*
 * CareHub Plus — Tarefas / Argumentos de navegação
 *
 * Representa o contexto com que a rota de Tarefas é aberta. Mantém explícito
 * quando a tela funciona como seletora de uma tarefa para SOS, sem depender
 * de Map ou flags soltas no extra do roteador.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

/// Dados de navegação para abrir a tela de Tarefas.
class TasksNavigationArgs {
  const TasksNavigationArgs({
    required this.careRecipientId,
    this.isSosSelectionMode = false,
  });

  /// Perfil cuidado cujas tarefas devem ser exibidas.
  final String careRecipientId;

  /// Quando `true`, a tela devolve a tarefa escolhida ao SOS já aberto.
  final bool isSosSelectionMode;
}
