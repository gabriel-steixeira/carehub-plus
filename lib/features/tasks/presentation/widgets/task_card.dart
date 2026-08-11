import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';

/// Redesigned Task Card with colored left accent strip, category & time header,
/// bold title, assigned caregiver info, and right completion radio button.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompletion,
    required this.onTapDetail,
  });

  final TaskModel task;
  final VoidCallback onToggleCompletion;
  final VoidCallback onTapDetail;

  String get _formattedTime {
    final time = task.scheduledTime;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final category = task.category;
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTap: onTapDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left Color Bar Strip
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),

              // 2. Main Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Left Details (Category, Title, Responsible)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Header Row: Category Icon + Label + Dot + Time
                            Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _formattedTime,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Task Title
                            Text(
                              task.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // Assigned Responsible Row
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Responsável: ${task.assignedToName ?? 'Eu'}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Checkbox Circle Button
                      GestureDetector(
                        onTap: onToggleCompletion,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(left: AppSpacing.sm),
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
                                  color: Colors.white,
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
