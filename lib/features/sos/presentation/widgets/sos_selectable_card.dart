/*
 * CareHub Plus — SOS / Cartão selecionável
 *
 * Casca visual comum das duas listas da tela de SOS (tarefas e rede de apoio):
 * painel tingido de lilás quando escolhido, cartão de borda quando não. Existe
 * para as duas listas nunca divergirem de aparência — mudar aqui muda nos dois
 * lugares.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_tinted_card.dart';

/// Item de lista selecionável do SOS.
class SosSelectableCard extends StatelessWidget {
  const SosSelectableCard({
    super.key,
    required this.child,
    required this.isSelected,
    this.onTap,
  });

  /// Conteúdo do item (ocupa toda a largura restante).
  final Widget child;

  /// Quando `true`, o item aparece tingido e com a marca de seleção preenchida.
  final bool isSelected;

  /// Quando `null`, o item é apenas informativo: sem toque e sem marca.
  final VoidCallback? onTap;

  /// Padding igual nas duas variações — sem isso o item "pula" de altura ao
  /// ser selecionado.
  static const EdgeInsets _padding = EdgeInsets.all(AppSpacing.smMd);

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(child: child),
        if (onTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _SelectionMark(isSelected: isSelected),
        ],
      ],
    );

    final card = isSelected
        ? AppTintedCard(
            tint: AppColors.primary,
            padding: _padding,
            child: content,
          )
        : AppCard(
            variant: AppCardVariant.outlined,
            padding: _padding,
            child: content,
          );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Círculo de seleção, no mesmo desenho do card de tarefas.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.isSelected});

  final bool isSelected;

  static const double _size = 28.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.textInverse,
            )
          : null,
    );
  }
}
