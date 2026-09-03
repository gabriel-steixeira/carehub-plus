/*
 * CareHub Plus — Widget Compartilhado / Seletor de Categoria em Chips
 *
 * Fileira horizontal de chips de categoria com um chip "+" ao final para abrir
 * o gerenciador (`ManageCategoriesBottomSheet`). Usado por Tasks e Chat para
 * que os dois filtros de categoria fiquem visualmente idênticos.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/categories/domain/entities/care_category_entity.dart';
import '../../features/categories/presentation/models/category_visuals.dart';

/// Fileira de chips "Todos" + uma por categoria + botão de gerenciar.
class CategoryChipSelector extends StatelessWidget {
  const CategoryChipSelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onManageCategories,
  });

  /// Categorias disponíveis, na ordem em que devem aparecer.
  final List<CareCategoryEntity> categories;

  /// Id da categoria selecionada, ou `null` para "Todos".
  final String? selectedCategoryId;

  /// Disparado com o id tocado, ou `null` ao tocar em "Todos".
  final ValueChanged<String?> onCategorySelected;

  /// Disparado ao tocar no chip "+", que abre o gerenciador de categorias.
  final VoidCallback onManageCategories;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _CategoryChip(
            label: 'Todos',
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final category in categories) ...[
            _CategoryChip(
              label: category.label,
              icon: iconForCategory(category),
              color: colorForCategory(category),
              isSelected: selectedCategoryId == category.id,
              onTap: () => onCategorySelected(
                selectedCategoryId == category.id ? null : category.id,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          _ManageCategoriesChip(onTap: onManageCategories),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filtrar por $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTypography.resolve(
                  text: label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip "+" que abre o gerenciador de categorias.
class _ManageCategoriesChip extends StatelessWidget {
  const _ManageCategoriesChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Gerenciar categorias',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.add, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
