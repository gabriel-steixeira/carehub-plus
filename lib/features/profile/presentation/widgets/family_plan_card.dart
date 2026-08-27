/*
 * CareHub Plus — Perfil / Cartão do Plano
 *
 * Mostra o plano contratado quando existe e usa o snapshot do contrato para
 * exibir o valor originalmente registrado, sem substituir esse valor pelo
 * preço atual do catálogo remoto.
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
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../subscriptions/domain/entities/contracted_subscription_entity.dart';
import '../../../subscriptions/domain/entities/subscription_plan_entity.dart';
import 'profile_icon_badge.dart';

/// Cartão do plano de assinatura do cuidador.
class FamilyPlanCard extends StatelessWidget {
  const FamilyPlanCard({
    super.key,
    required this.plan,
    required this.subscription,
    required this.onChangePlan,
  });

  final SubscriptionPlanEntity? plan;
  final ContractedSubscriptionEntity? subscription;

  /// Abre a troca de plano.
  final VoidCallback onChangePlan;

  String _formattedPrice() {
    final amountCents =
        subscription?.amountCents ?? ((plan?.monthlyPrice ?? 0) * 100).round();
    final value = (amountCents / 100).toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $value';
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = plan;
    final currentSubscription = subscription;
    if (currentPlan == null && currentSubscription == null) {
      return AppCard(
        variant: AppCardVariant.outlined,
        child: Row(
          children: [
            const ProfileIconBadge(icon: Icons.workspace_premium_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Nenhum plano contratado',
                style: AppTypography.titleMedium,
              ),
            ),
            AppButton(
              label: 'Escolher',
              onPressed: onChangePlan,
              variant: AppButtonVariant.ghost,
              fullWidth: false,
            ),
          ],
        ),
      );
    }

    final planName = currentSubscription?.planNameSnapshot ?? currentPlan!.name;
    final maxMembers =
        currentSubscription?.maxMembersSnapshot ?? currentPlan?.maxMembers;
    final billingCycle = currentSubscription?.billingCycle;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ProfileIconBadge(icon: Icons.workspace_premium_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      planName,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const _PlanStatusBadge(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Trocar',
                onPressed: onChangePlan,
                variant: AppButtonVariant.ghost,
                fullWidth: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _formattedPrice(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.averiaTitleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            billingCycle == SubscriptionBillingCycle.annual
                                ? '/ano'
                                : '/mês',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currentSubscription != null
                          ? 'Valor registrado na contratação'
                          : 'Valor atual do catálogo; contrato antigo sem snapshot de preço',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (maxMembers != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: AppSpacing.md,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'Até $maxMembers pessoas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Etiqueta que indica que existe um plano selecionado para a conta.
class _PlanStatusBadge extends StatelessWidget {
  const _PlanStatusBadge();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        'ATIVO',
        style: AppTypography.sectionLabel.copyWith(color: color),
      ),
    );
  }
}
