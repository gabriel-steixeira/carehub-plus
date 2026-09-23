import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../categories/domain/entities/care_category_entity.dart';
import '../../../categories/presentation/models/category_visuals.dart';
import '../../data/models/chat_room_model.dart';

/// Cartão de um assunto que encaminha para a conversa correspondente.
class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.room,
    required this.category,
    required this.onTap,
  });

  final ChatRoomModel room;

  /// Categoria já resolvida pela tela a partir de `room.categoryId`.
  final CareCategoryEntity category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = colorForCategory(category);
    final categoryIcon = iconForCategory(category);

    return Semantics(
      button: true,
      label: 'Assunto ${category.label}: ${room.title}',
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
                  color: accentColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: AppMemberAvatar(
                    photo: room.responsibleMemberPhotoUrl,
                    diameter: AppSpacing.xxl,
                  ),
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
                              categoryIcon,
                              size: AppSpacing.md,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              category.label,
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
                                style: AppTypography.averiaTitleLarge.copyWith(
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
