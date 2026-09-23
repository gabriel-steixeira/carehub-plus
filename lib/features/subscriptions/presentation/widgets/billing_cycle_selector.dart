/*
 * CareHub Plus — Assinaturas / Seletor de Ciclo
 *
 * Exibe a escolha entre cobrança mensal e anual com o mesmo controle segmentado
 * em todos os tamanhos de tela.
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
import '../../domain/entities/subscription_plan_entity.dart';

class BillingCycleSelector extends StatelessWidget {
  const BillingCycleSelector({
    super.key,
    required this.selectedCycle,
    required this.onChanged,
  });

  final SubscriptionBillingCycle selectedCycle;
  final ValueChanged<SubscriptionBillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final cycle in SubscriptionBillingCycle.values)
            _CycleOption(
              cycle: cycle,
              isSelected: selectedCycle == cycle,
              onTap: () => onChanged(cycle),
            ),
        ],
      ),
    );
  }
}

class AnnualSavingsBadge extends StatelessWidget {
  const AnnualSavingsBadge({super.key, required this.discountPercent});

  final int discountPercent;

  @override
  Widget build(BuildContext context) {
    final label = 'Economize $discountPercent%';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.resolve(
          text: label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  const _CycleOption({
    required this.cycle,
    required this.isSelected,
    required this.onTap,
  });

  final SubscriptionBillingCycle cycle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.background : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: isSelected ? AppShadows.raised : null,
            ),
            child: Text(
              cycle.label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
