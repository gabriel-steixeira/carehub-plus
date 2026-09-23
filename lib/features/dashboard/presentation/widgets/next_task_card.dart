/*
 * CareHub Plus — Dashboard / Next Task Card & Overdue Card
 *
 * Dois cartões complementares do resumo diário:
 *  • NextTaskCard — exibe a próxima tarefa pendente mais próxima em horário.
 *  • OverdueCard  — exibe a contagem de tarefas atrasadas. Só renderiza
 *                   quando há pelo menos uma tarefa atrasada.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/next_task_preview_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Next Task Card
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe a próxima tarefa pendente mais próxima.
///
/// Quando [nextTask] é nulo (não há tarefas pendentes), exibe um estado
/// positivo indicando que não há compromissos pendentes.
class NextTaskCard extends StatelessWidget {
  const NextTaskCard({
    super.key,
    this.nextTask,
    this.onTap,
  });

  final NextTaskPreviewModel? nextTask;

  /// Navega para a tela de tarefas ao tocar.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: nextTask != null ? _WithTask(task: nextTask!) : const _NoTask(),
      ),
    );
  }
}

class _WithTask extends StatelessWidget {
  const _WithTask({required this.task});

  final NextTaskPreviewModel task;

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(task.scheduledTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próxima tarefa',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    time,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (task.assignedToName != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                task.assignedToName!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _NoTask extends StatelessWidget {
  const _NoTask();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(
            Icons.task_alt_rounded,
            color: AppColors.success,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Próxima tarefa',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Nada pendente por enquanto',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overdue Card
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe o número de tarefas atrasadas.
///
/// Deve ser renderizado **apenas quando [overdueCount] > 0** — a tela pai
/// é responsável por ocultar este widget quando não há atrasos, evitando
/// ruído visual desnecessário quando tudo está em dia.
class OverdueCard extends StatelessWidget {
  const OverdueCard({
    super.key,
    required this.overdueCount,
    this.onTap,
  });

  final int overdueCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overdueCount == 1
                        ? '1 tarefa atrasada'
                        : '$overdueCount tarefas atrasadas',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Toque para ver e resolver',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
