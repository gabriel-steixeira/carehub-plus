/*
 * CareHub Plus — Apresentação / Cabeçalho de Tarefas
 *
 * Título "Tarefas", contador de pendentes/concluídas e botão "+ Nova".
 * Extraído de `tasks_page.dart` para manter a página como composição, e não
 * implementação (ver `architecture.md` — limite de ~250 linhas por página).
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Cabeçalho da lista de tarefas: título, contadores e ação de criar.
class TasksHeaderSection extends StatelessWidget {
  const TasksHeaderSection({
    super.key,
    required this.pendingCount,
    required this.completedCount,
    required this.onCreateTask,
  });

  final int pendingCount;
  final int completedCount;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarefas',
              style: AppTypography.averiaDisplayLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$pendingCount pendentes, $completedCount concluídas',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        _NewTaskButton(onPressed: onCreateTask),
      ],
    );
  }
}

class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: AppShadows.accent(AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: AppColors.textInverse, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Nova',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
