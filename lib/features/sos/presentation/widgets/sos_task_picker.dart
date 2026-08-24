/*
 * CareHub Plus — SOS / Escolha da tarefa
 *
 * Lista as tarefas em aberto do perfil selecionado para a cuidadora indicar em
 * qual delas precisa de ajuda. Também é o caminho de quem chegou pelo arrastar
 * do card na tela de Tarefas: nesse caso a tarefa já vem marcada e pode ser
 * trocada aqui.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_tinted_card.dart';
import '../../../tasks/data/models/task_model.dart';
import 'sos_selectable_card.dart';

/// Seletor da tarefa que motiva o pedido de ajuda.
class SosTaskPicker extends StatelessWidget {
  const SosTaskPicker({
    super.key,
    required this.tasks,
    required this.selectedTaskId,
    required this.onTaskSelected,
  });

  /// Tarefas em aberto do perfil atual.
  final List<TaskModel> tasks;

  /// Id da tarefa marcada, se houver.
  final String? selectedTaskId;

  /// Informa qual tarefa foi tocada — tocar na marcada desmarca.
  final ValueChanged<String> onTaskSelected;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const AppEmptyView(
        message: 'Nenhuma tarefa em aberto para este perfil.\n'
            'Crie uma tarefa antes de pedir ajuda.',
        icon: Icons.event_available_rounded,
      );
    }

    // Encontra a tarefa selecionada
    TaskModel? selectedTask;
    if (selectedTaskId != null) {
      try {
        selectedTask = tasks.firstWhere((t) => t.id == selectedTaskId);
      } catch (e) {
        selectedTask = null;
      }
    }

    // Tarefas não selecionadas
    final otherTasks = selectedTaskId != null && selectedTask != null
        ? tasks.where((t) => t.id != selectedTaskId).toList()
        : (selectedTaskId == null ? tasks : tasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarefa selecionada (card destacado)
        if (selectedTask != null) ...[
          AppTintedCard(
            tint: AppColors.primary,
            padding: const EdgeInsets.all(AppSpacing.smMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TaskSummary(task: selectedTask),
                ),
                const SizedBox(width: AppSpacing.sm),
                _EditTaskButton(
                  onPressed: () => onTaskSelected(selectedTask!.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Aviso de tempo médio de resposta
          const _AverageResponseTimeCard(),
          const SizedBox(height: AppSpacing.md),
        ],
        // Lista de outras tarefas para seleção
        if (otherTasks.isNotEmpty) ...[
          if (selectedTask != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Ou escolha outra tarefa:',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          for (final task in otherTasks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SosSelectableCard(
                isSelected: false,
                onTap: () => onTaskSelected(task.id),
                child: _TaskSummary(task: task),
              ),
            ),
        ],
      ],
    );
  }
}

/// Resumo de uma tarefa: horário, título e responsável.
class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.task});

  final TaskModel task;

  String get _formattedTime {
    final hour = task.scheduledTime.hour.toString().padLeft(2, '0');
    final minute = task.scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _formattedTime,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (task.isOverdue) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Atrasada',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          task.title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Responsável: ${task.assignedToName ?? 'Eu'}',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Botão pequenininho "Alterar" para editar a tarefa selecionada.
class _EditTaskButton extends StatelessWidget {
  const _EditTaskButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Symbols.edit_rounded, size: 16),
      label: Text(
        'Alterar',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Card de aviso do tempo médio de resposta da rede de apoio.
class _AverageResponseTimeCard extends StatelessWidget {
  const _AverageResponseTimeCard();

  // Tempo médio padrão em minutos. Futuramente, isso pode vir da rede de apoio.
  static const int _defaultMinutes = 4;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.filled,
      padding: const EdgeInsets.all(AppSpacing.smMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Icon(
                Icons.schedule_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tempo médio de resposta',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'da sua rede: $_defaultMinutes minutos',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
