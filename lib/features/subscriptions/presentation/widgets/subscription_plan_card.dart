/*
 * CareHub Plus — Assinaturas / Cartão de Plano
 *
 * Apresenta preço, descrição, benefícios e ação de um plano, destacando o plano
 * atual sem conhecer a origem dos dados ou executar regras de contratação. Quando
 * há contrato, mostra o valor registrado nele em vez do preço vivo do catálogo.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/contracted_subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.contractedSubscription,
    required this.isCurrent,
    required this.onAction,
  });

  final SubscriptionPlanEntity plan;
  final SubscriptionBillingCycle billingCycle;
  final ContractedSubscriptionEntity? contractedSubscription;
  final bool isCurrent;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = plan.badgeLabel;
    final footnote = plan.footnote;
    final hasContract = contractedSubscription?.planId == plan.id;

    return Semantics(
      container: true,
      label: 'Plano ${plan.name}${hasContract ? ', plano contratado' : ''}',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              top: badgeLabel == null ? 0 : AppSpacing.smMd,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: hasContract ? AppColors.primaryDark : AppColors.border,
                width: hasContract ? AppSpacing.xs / 2 : 1,
              ),
              boxShadow: hasContract
                  ? AppShadows.accent(AppColors.primary)
                  : AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: badgeLabel == null ? 0 : AppSpacing.sm),
                Text(
                  plan.name,
                  style: AppTypography.averiaTitleLarge.copyWith(
                    color: hasContract
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.smMd),
                _PlanPrice(
                  plan: plan,
                  billingCycle: billingCycle,
                  contractedSubscription: contractedSubscription,
                ),
                const SizedBox(height: AppSpacing.smMd),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.smMd),
                for (final benefit in plan.benefits) ...[
                  _BenefitItem(label: benefit, isHighlighted: hasContract),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: hasContract
                      ? 'Plano Contratado'
                      : isCurrent
                      ? 'Plano Atual'
                      : plan.actionLabel,
                  onPressed: hasContract ? null : onAction,
                  variant: plan.isFree
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                ),
                if (footnote != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    footnote,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badgeLabel != null)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.smMd,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.background,
                    width: AppSpacing.xs / 2,
                  ),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTypography.resolve(
                    text: badgeLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bloco de preço: valor do contrato ou valor vigente do catálogo.
class _PlanPrice extends StatelessWidget {
  const _PlanPrice({
    required this.plan,
    required this.billingCycle,
    required this.contractedSubscription,
  });

  final SubscriptionPlanEntity plan;
  final SubscriptionBillingCycle billingCycle;
  final ContractedSubscriptionEntity? contractedSubscription;

  @override
  Widget build(BuildContext context) {
    final contract = contractedSubscription;
    if (contract != null && contract.planId == plan.id) {
      final suffix = contract.billingCycle == SubscriptionBillingCycle.annual
          ? '/ano'
          : '/mês';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriceLine(amount: _formatCurrency(contract.amount), suffix: suffix),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Valor contratado, protegido contra reajustes do catálogo',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (plan.isFree) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PriceLine(amount: 'Grátis', suffix: ''),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sem cartão de crédito',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final isAnnual = billingCycle == SubscriptionBillingCycle.annual;
    final monthly = _formatCurrency(plan.monthlyPrice);
    final annual = _formatCurrency(plan.annualPriceFor());
    final monthlyInAnnual = _formatCurrency(
      plan.monthlyEquivalentFor(SubscriptionBillingCycle.annual),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriceLine(
          amount: isAnnual ? annual : monthly,
          suffix: isAnnual ? '/ano' : '/mês',
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.smMd,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPanel),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAnnual
                    ? 'Equivale a $monthlyInAnnual por mês'
                    : 'No anual: $annual por ano',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (plan.annualSavings > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Economia de ${_formatCurrency(plan.annualSavings)} por ano',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceFirst('.', ',');
    return 'R\$ $formatted';
  }
}

/// Valor em destaque com o período em texto de apoio.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.amount, required this.suffix});

  final String amount;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          amount,
          style: AppTypography.averiaHeadlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (suffix.isNotEmpty)
          Text(
            suffix,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.label, required this.isHighlighted});

  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? AppColors.primaryDark : AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: color,
          size: AppSpacing.md,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
