/*
 * CareHub Plus — Convites / Convite aceito
 *
 * Confirma que o perfil compartilhado já está na conta e leva para o
 * início. Só desenha o que recebe.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/redeemed_invite_entity.dart';

/// Estado de sucesso da tela "Tenho um convite".
class RedeemInviteSuccessView extends StatelessWidget {
  const RedeemInviteSuccessView({
    super.key,
    required this.redeemed,
    required this.onGoHome,
    required this.onUseAnother,
  });

  final RedeemedInviteEntity redeemed;
  final VoidCallback onGoHome;
  final VoidCallback onUseAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Convite aceito',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Agora você acompanha os cuidados de ${redeemed.firstName}. '
                  'O perfil já está selecionado no início.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Ir para o início', onPressed: onGoHome),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Usar outro código',
          variant: AppButtonVariant.ghost,
          onPressed: onUseAnother,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
