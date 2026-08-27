/*
 * CareHub Plus — Assinaturas / Conteúdo Responsivo
 *
 * Organiza título, seletor e cartões em coluna no celular e em múltiplas colunas
 * nas telas maiores, mantendo uma única representação dos dados dos planos e
 * destacando o valor do contrato ativo separado do catálogo.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../../shared/widgets/app_responsive_layout.dart';
import '../../domain/entities/contracted_subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import 'billing_cycle_selector.dart';
import 'subscription_plan_card.dart';

class SubscriptionsContent extends StatelessWidget {
  const SubscriptionsContent({
    super.key,
    required this.plans,
    required this.currentPlanId,
    required this.billingCycle,
    required this.annualDiscountPercent,
    required this.contractedSubscription,
    required this.onBillingCycleChanged,
    required this.onPlanAction,
  });

  final List<SubscriptionPlanEntity> plans;
  final String currentPlanId;
  final SubscriptionBillingCycle billingCycle;
  final int annualDiscountPercent;
  final ContractedSubscriptionEntity? contractedSubscription;
  final ValueChanged<SubscriptionBillingCycle> onBillingCycleChanged;
  final ValueChanged<String> onPlanAction;

  SubscriptionPlanEntity? _currentCatalogPlan() {
    for (final plan in plans) {
      if (plan.id == currentPlanId) return plan;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assinaturas',
            style: AppTypography.averiaHeadlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Veja seu plano contratado e compare as opções disponíveis.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.scaleSpacing(AppSpacing.md)),
          ContractedSubscriptionSummary(
            subscription: contractedSubscription,
            currentPlan: _currentCatalogPlan(),
          ),
          SizedBox(height: context.sectionSpacing),
          Center(
            child: Column(
              children: [
                BillingCycleSelector(
                  selectedCycle: billingCycle,
                  onChanged: onBillingCycleChanged,
                ),
                if (annualDiscountPercent > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AnnualSavingsBadge(discountPercent: annualDiscountPercent),
                ],
              ],
            ),
          ),
          if (plans.isEmpty) ...[
            SizedBox(height: context.sectionSpacing),
            const AppEmptyView(
              message: 'Nenhum plano está disponível no momento.',
              icon: Icons.workspace_premium_outlined,
            ),
          ] else ...[
            SizedBox(height: context.sectionSpacing),
            AppResponsiveLayout(
              mobile: _PlanColumn(
                plans: plans,
                currentPlanId: currentPlanId,
                billingCycle: billingCycle,
                contractedSubscription: contractedSubscription,
                onPlanAction: onPlanAction,
              ),
              tablet: _PlanWrap(
                columns: 2,
                plans: plans,
                currentPlanId: currentPlanId,
                billingCycle: billingCycle,
                contractedSubscription: contractedSubscription,
                onPlanAction: onPlanAction,
              ),
              desktop: _PlanWrap(
                columns: 3,
                plans: plans,
                currentPlanId: currentPlanId,
                billingCycle: billingCycle,
                contractedSubscription: contractedSubscription,
                onPlanAction: onPlanAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mostra o contrato ativo ou identifica um registro antigo sem preço histórico.
class ContractedSubscriptionSummary extends StatelessWidget {
  const ContractedSubscriptionSummary({
    super.key,
    required this.subscription,
    required this.currentPlan,
  });

  final ContractedSubscriptionEntity? subscription;
  final SubscriptionPlanEntity? currentPlan;

  String _formatCurrency(int cents) {
    final value = (cents / 100).toStringAsFixed(2).replaceFirst('.', ',');
    return 'R\$ $value';
  }

  @override
  Widget build(BuildContext context) {
    final current = subscription;
    final legacyPlan = currentPlan;
    final hasPlan = current != null || legacyPlan != null;

    return AppCard(
      variant: AppCardVariant.filled,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.primaryDark,
            size: AppSpacing.xl,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: !hasPlan
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano contratado',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Nenhum plano contratado foi registrado ainda.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : current != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryTitle(
                        name: current.planNameSnapshot,
                        status: 'ATIVO',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_formatCurrency(current.amountCents)} /${current.billingCycle == SubscriptionBillingCycle.annual ? 'ano' : 'mês'}',
                        style: AppTypography.averiaTitleLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Valor registrado na contratação. Reajustes no catálogo não alteram este valor.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryTitle(
                        name: legacyPlan!.name,
                        status: 'PLANO ATUAL',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_formatCurrency((legacyPlan.monthlyPrice * 100).round())} /mês',
                        style: AppTypography.averiaTitleLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Este registro antigo não guarda o valor pago. Novas contratações usam o preço atual do catálogo.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTitle extends StatelessWidget {
  const _SummaryTitle({required this.name, required this.status});

  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          status,
          style: AppTypography.resolve(
            text: status,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanColumn extends StatelessWidget {
  const _PlanColumn({
    required this.plans,
    required this.currentPlanId,
    required this.billingCycle,
    required this.contractedSubscription,
    required this.onPlanAction,
  });

  final List<SubscriptionPlanEntity> plans;
  final String currentPlanId;
  final SubscriptionBillingCycle billingCycle;
  final ContractedSubscriptionEntity? contractedSubscription;
  final ValueChanged<String> onPlanAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < plans.length; index++) ...[
          _PlanCardForState(
            plan: plans[index],
            currentPlanId: currentPlanId,
            billingCycle: billingCycle,
            contractedSubscription: contractedSubscription,
            onPlanAction: onPlanAction,
          ),
          if (index < plans.length - 1)
            SizedBox(height: context.sectionSpacing),
        ],
      ],
    );
  }
}

class _PlanWrap extends StatelessWidget {
  const _PlanWrap({
    required this.columns,
    required this.plans,
    required this.currentPlanId,
    required this.billingCycle,
    required this.contractedSubscription,
    required this.onPlanAction,
  });

  final int columns;
  final List<SubscriptionPlanEntity> plans;
  final String currentPlanId;
  final SubscriptionBillingCycle billingCycle;
  final ContractedSubscriptionEntity? contractedSubscription;
  final ValueChanged<String> onPlanAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = context.sectionSpacing;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final plan in plans)
              SizedBox(
                width: cardWidth,
                child: _PlanCardForState(
                  plan: plan,
                  currentPlanId: currentPlanId,
                  billingCycle: billingCycle,
                  contractedSubscription: contractedSubscription,
                  onPlanAction: onPlanAction,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanCardForState extends StatelessWidget {
  const _PlanCardForState({
    required this.plan,
    required this.currentPlanId,
    required this.billingCycle,
    required this.contractedSubscription,
    required this.onPlanAction,
  });

  final SubscriptionPlanEntity plan;
  final String currentPlanId;
  final SubscriptionBillingCycle billingCycle;
  final ContractedSubscriptionEntity? contractedSubscription;
  final ValueChanged<String> onPlanAction;

  @override
  Widget build(BuildContext context) {
    return SubscriptionPlanCard(
      plan: plan,
      billingCycle: billingCycle,
      contractedSubscription: contractedSubscription,
      isCurrent: currentPlanId == plan.id,
      onAction: () => onPlanAction(plan.id),
    );
  }
}
