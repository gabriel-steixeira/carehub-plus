/*
 * CareHub Plus — SOS / Tarefa selecionada
 *
 * Exibe somente o resumo da tarefa que motivará o alerta. Para alterá-la, a
 * cuidadora retorna à tela de Tarefas e usa o gesto SOS no card desejado;
 * assim o SOS não replica nem mistura a lista de tarefas no seu fluxo.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/categories/domain/entities/care_category_entity.dart';
import '../../../../features/categories/presentation/bloc/care_categories_bloc.dart';
import '../../../../features/categories/presentation/models/category_visuals.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../tasks/data/models/task_model.dart';

/// Mostra a tarefa escolhida para o alerta SOS.
class SosTaskPicker extends StatelessWidget {
  const SosTaskPicker({
    super.key,
    required this.tasks,
    required this.selectedTaskId,
    required this.onChangeTask,
  });

  /// Tarefas em aberto do perfil atual.
  final List<TaskModel> tasks;

  /// Id da tarefa escolhida pelo BLoC.
  final String? selectedTaskId;

  /// Abre Tarefas para escolher outro card pelo gesto SOS.
  final VoidCallback onChangeTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const AppEmptyView(
        message:
            'Nenhuma tarefa em aberto para este perfil.\n'
            'Crie uma tarefa antes de pedir ajuda.',
        icon: Icons.event_available_rounded,
      );
    }

    return BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
      builder: (context, categoriesState) {
        final selectedTask = _findSelectedTask();
        if (selectedTask == null) {
          return const AppEmptyView(
            message: 'Não foi possível localizar a tarefa selecionada.',
            icon: Icons.task_alt_rounded,
          );
        }

        return _SelectedTaskCard(
          task: selectedTask,
          category: _findCategory(categoriesState.categories, selectedTask),
          onChangeTask: onChangeTask,
        );
      },
    );
  }

  TaskModel? _findSelectedTask() {
    if (selectedTaskId == null) return null;
    for (final task in tasks) {
      if (task.id == selectedTaskId) return task;
    }
    return null;
  }

  CareCategoryEntity? _findCategory(
    List<CareCategoryEntity> categories,
    TaskModel task,
  ) {
    for (final category in categories) {
      if (category.id == task.categoryId) return category;
    }
    return null;
  }
}

/// Card da tarefa selecionada com a mesma linguagem visual dos cards de
/// Tarefas. No SOS, a ação contextual é trocar a tarefa, não concluí-la.
class _SelectedTaskCard extends StatelessWidget {
  const _SelectedTaskCard({
    required this.task,
    required this.category,
    required this.onChangeTask,
  });

  final TaskModel task;
  final CareCategoryEntity? category;
  final VoidCallback onChangeTask;

  String get _formattedTime {
    final hour = task.scheduledTime.hour.toString().padLeft(2, '0');
    final minute = task.scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _statusLabel => task.isOverdue ? 'Atrasada' : 'Pendente';

  Color get _statusColor =>
      task.isOverdue ? AppColors.error : AppColors.warning;

  CareCategoryEntity get _displayCategory =>
      category ??
      CareCategoryEntity(
        id: task.categoryId,
        label: task.categoryId,
        iconKey: 'other',
        colorKey: 'grey',
      );

  @override
  Widget build(BuildContext context) {
    final displayCategory = _displayCategory;
    final categoryColor = colorForCategory(displayCategory);
    final categoryIcon = iconForCategory(displayCategory);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: AppSpacing.xs,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                categoryIcon,
                                size: AppSpacing.md,
                                color: categoryColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  displayCategory.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                child: Text(
                                  '•',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                _formattedTime,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: AppSpacing.smMd,
                                backgroundColor: AppColors.surfaceVariant,
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: AppSpacing.md,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Responsável: ${task.assignedToName ?? 'Eu'}',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Status: '),
                                TextSpan(
                                  text: _statusLabel,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: _statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Alterar',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.edit_outlined,
                      fullWidth: false,
                      onPressed: onChangeTask,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
