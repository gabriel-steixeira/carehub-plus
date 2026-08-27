import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../categories/domain/entities/care_category_entity.dart';
import '../../../categories/presentation/models/category_visuals.dart';
import '../../data/models/task_model.dart';
import '../bloc/tasks_bloc.dart';

/// Bottom sheet showing task details with check-in option (note).
class TaskDetailModal extends StatefulWidget {
  const TaskDetailModal({
    super.key,
    required this.task,
    required this.category,
  });

  final TaskModel task;
  final CareCategoryEntity category;

  static Future<void> show(
    BuildContext context,
    TaskModel task,
    CareCategoryEntity category,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: TaskDetailModal(task: task, category: category),
      ),
    );
  }

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.task.completionNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final category = widget.category;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorForCategory(category).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    iconForCategory(category),
                    color: colorForCategory(category),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: colorForCategory(category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        task.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description.isNotEmpty) ...[
                    Text(
                      'Descrição / Instruções',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horário Previsto',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${task.scheduledTime.hour.toString().padLeft(2, '0')}:${task.scheduledTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Frequência',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            task.frequency.label,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Check-in Note Input
                  AppTextField(
                    controller: _noteController,
                    label: 'Nota de realização (Check-in)',
                    hint: 'Ex: Medicação administrada sem intercorrências.',
                    prefixIcon: Icons.edit_note_outlined,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Actions
                  AppButton(
                    label: task.isCompleted
                        ? 'Desmarcar Conclusão'
                        : 'Concluir Tarefa (Check-in)',
                    variant: task.isCompleted
                        ? AppButtonVariant.secondary
                        : AppButtonVariant.primary,
                    onPressed: () {
                      context.read<TasksBloc>().add(
                            TaskToggleCompletionEvent(
                              taskId: task.id,
                              note: _noteController.text.trim().isEmpty
                                  ? null
                                  : _noteController.text.trim(),
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  AppButton(
                    label: 'Excluir Tarefa',
                    variant: AppButtonVariant.destructive,
                    onPressed: () {
                      context
                          .read<TasksBloc>()
                          .add(TaskDeleteEvent(taskId: task.id));
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
