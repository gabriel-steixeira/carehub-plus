import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// App-wide bottom navigation bar.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.chatBadgeCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// Quantidade de chats não lidos exibida no badge do item Chat.
  final int chatBadgeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1.0),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildItem(
                index: 0,
                icon: Symbols.home_rounded,
                activeIcon: Symbols.home_rounded,
                label: 'Início',
              ),
              _buildItem(
                index: 1,
                icon: Symbols.select_check_box_rounded,
                activeIcon: Symbols.select_check_box_rounded,
                label: 'Tarefas',
              ),
              _buildCoraButton(index: 2),
              _buildItem(
                index: 3,
                icon: Symbols.chat_bubble_rounded,
                activeIcon: Symbols.chat_bubble_rounded,
                label: 'Chat',
                badgeCount: chatBadgeCount,
              ),
              _buildItem(
                index: 4,
                icon: Symbols.shield_with_heart_rounded,
                activeIcon: Symbols.shield_with_heart_rounded,
                label: 'SOS',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap?.call(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 24,
                  fill: isActive ? 1.0 : 0.0,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: AppTypography.resolve(
                          text: '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.resolve(
                text: label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoraButton({required int index}) {
    final isActive = currentIndex == index;
    final activeColor = AppColors.primary;
    final color = isActive ? activeColor : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap?.call(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFAF9EE0), Color(0xFF7B61C8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome, // Sparkles icon representing Cora
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cora',
              style: AppTypography.resolve(
                text: 'Cora',
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
