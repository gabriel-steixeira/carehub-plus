/*
 * CareHub Plus — Apresentação / Ordenação de Tarefas
 *
 * Dropdown "Ordenar por: Horário v" da lista de tarefas. Extraído de
 * `tasks_page.dart` para manter a página como composição.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Seletor de critério de ordenação da lista de tarefas.
class TasksSortDropdown extends StatelessWidget {
  const TasksSortDropdown({
    super.key,
    required this.sortOption,
    required this.onSortSelected,
  });

  /// Valor atual: `'time'`, `'category'` ou `'status'`.
  final String sortOption;
  final ValueChanged<String> onSortSelected;

  String get _label => switch (sortOption) {
        'category' => 'Categoria',
        'status' => 'Status',
        _ => 'Horário',
      };

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        initialValue: sortOption,
        onSelected: onSortSelected,
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'time', child: Text('Horário')),
          PopupMenuItem(value: 'category', child: Text('Categoria')),
          PopupMenuItem(value: 'status', child: Text('Status')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Ordenar por: $_label',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
