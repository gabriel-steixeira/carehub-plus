/*
 * CareHub Plus — SOS / Confirmação de cancelamento
 *
 * Passo de confirmação antes de derrubar um alerta em andamento. Cancelar por
 * engano é o pior erro possível nesse fluxo, então a ação destrutiva exige um
 * segundo toque e a opção de manter o alerta vem primeiro.
 *
 * Devolve `true` quando a cuidadora confirma o cancelamento.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_tinted_card.dart';

/// Bottom sheet de confirmação do cancelamento do alerta.
class SosCancelConfirmationSheet extends StatelessWidget {
  const SosCancelConfirmationSheet({super.key});

  static const double _handleWidth = 40.0;
  static const double _iconBadgeSize = 72.0;

  /// Abre o sheet e devolve `true` apenas se o cancelamento for confirmado.
  static Future<bool> show(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SosCancelConfirmationSheet(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _handleWidth,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: _iconBadgeSize,
              height: _iconBadgeSize,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Confirmar cancelamento?',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Deseja realmente cancelar o pedido de ajuda? '
              'Sua rede de apoio deixará de acompanhar esta tarefa.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Manter alerta',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Sim, cancelar',
              variant: AppButtonVariant.destructive,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTintedCard(
              tint: AppColors.primary,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nesta versão o alerta é simulado: o cancelamento '
                      'encerra o pedido apenas neste aparelho.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
