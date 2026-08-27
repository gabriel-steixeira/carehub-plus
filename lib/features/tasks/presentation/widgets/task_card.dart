import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../categories/domain/entities/care_category_entity.dart';
import '../../../categories/presentation/models/category_visuals.dart';
import '../../data/models/task_model.dart';

/// Redesigned Task Card with colored left accent strip, category & time header,
/// bold title, assigned caregiver info, and a contextual trailing action.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.category,
    required this.onToggleCompletion,
    required this.onTapDetail,
    this.onRequestSos,
  });

  final TaskModel task;

  /// Categoria já resolvida pela tela (`categories/`), a partir de
  /// `task.categoryId`. O card não conhece o BLoC de categorias — só recebe
  /// o resultado, mantendo a responsabilidade de leitura na página.
  final CareCategoryEntity category;
  final VoidCallback onToggleCompletion;
  final VoidCallback onTapDetail;

  /// Ação SOS visível usada apenas no modo contextual de escolha para SOS.
  /// Quando ausente, o card mantém o controle de conclusão padrão.
  final VoidCallback? onRequestSos;

  String get _formattedTime {
    final time = task.scheduledTime;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = colorForCategory(category);
    final categoryIcon = iconForCategory(category);
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTap: onRequestSos == null ? onTapDetail : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    category.label,
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
                              style: AppTypography.titleMedium.copyWith(
                                color: isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                AppMemberAvatar(
                                  photo: task.assignedToPhotoUrl,
                                  diameter: AppSpacing.smMd * 2,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (onRequestSos != null)
                        AppButton(
                          label: 'SOS',
                          variant: AppButtonVariant.destructive,
                          icon: Icons.emergency_rounded,
                          fullWidth: false,
                          onPressed: onRequestSos,
                        )
                      else
                        GestureDetector(
                          onTap: onToggleCompletion,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppColors.success
                                  : Colors.transparent,
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.success
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: AppColors.textInverse,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
