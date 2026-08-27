/*
 * CareHub Plus — Perfil / Cartão de Privacidade dos Dados
 *
 * Atalho para as configurações de visibilidade do perfil. Fica no formulário de
 * perfil porque é ali que a pessoa pensa em quem vê seus dados.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import 'profile_icon_badge.dart';

/// Cartão de acesso às configurações de privacidade.
class DataPrivacyCard extends StatelessWidget {
  const DataPrivacyCard({super.key, required this.onTap});

  /// Abre as configurações de privacidade.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: onTap,
      child: Row(
        children: [
          const ProfileIconBadge(icon: Icons.shield_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Privacidade dos Dados',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Configurar visibilidade do perfil',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
