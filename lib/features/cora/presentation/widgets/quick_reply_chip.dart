import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Quick action chips suggested by Cora AI.
class QuickReplyChip extends StatelessWidget {
  const QuickReplyChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      avatar: const Icon(
        Icons.auto_awesome_outlined,
        size: 14,
        color: AppColors.primary,
      ),
      label: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
