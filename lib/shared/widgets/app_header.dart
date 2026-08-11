import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Standard top header bar for main app screens (Home, Dashboard, etc.).
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.photoUrl,
    this.onSettingsPressed,
  });

  /// URL of the caregiver's profile photo.
  final String? photoUrl;

  /// Callback when settings button is pressed. Defaults to navigating to settings route.
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xl + AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Caregiver avatar and small logo
          Row(
            children: [
              // Caregiver Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),

              // Logo Pequeno
              Image.asset(
                'assets/images/logo_pequeno.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'CareHub+',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),

          // Right side: Settings gear
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
            onPressed: onSettingsPressed ??
                () {
                  context.push(AppRoutes.settings);
                },
          ),
        ],
      ),
    );
  }
}
