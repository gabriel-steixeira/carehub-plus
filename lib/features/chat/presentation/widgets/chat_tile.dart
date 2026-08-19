import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/chat_room_model.dart';
import '../bloc/chat_bloc.dart';

/// Cartão de um assunto que encaminha para a conversa correspondente.
class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.room,
    required this.category,
    required this.onTap,
  });

  final ChatRoomModel room;
  final ChatCategory category;
  final VoidCallback onTap;

  String get _categoryLabel => switch (category) {
    ChatCategory.health => 'Saúde',
    ChatCategory.food => 'Alimentação',
  };

  IconData get _categoryIcon => switch (category) {
    ChatCategory.health => Icons.medication_outlined,
    ChatCategory.food => Icons.restaurant_outlined,
  };

  Color get _accentColor => switch (category) {
    ChatCategory.health => AppColors.success,
    ChatCategory.food => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Assunto $_categoryLabel: ${room.title}',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.background,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: AppSpacing.xs,
                  height: AppSpacing.xxxl + AppSpacing.xl,
                  color: _accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _categoryIcon,
                              size: AppSpacing.md,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _categoryLabel,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (room.unreadCount > 0)
                              _UnreadBadge(count: room.unreadCount),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                room.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.lg,
        minHeight: AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textInverse,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
