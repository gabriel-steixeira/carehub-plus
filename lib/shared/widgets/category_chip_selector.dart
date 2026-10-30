/*
 * CareHub Plus — Widget Compartilhado / Pílulas de Categoria
 *
 * Fonte única da aparência das pílulas de categoria do app. Expõe três peças
 * que compartilham exatamente o mesmo visual (cápsula arredondada, ícone
 * pequeno, cor da categoria quando selecionada e sombra suave):
 *   • [CategoryPill]        — a pílula em si, reutilizável;
 *   • [CategoryChipSelector]— fileira de filtro ("Todos" + categorias + "+"),
 *                             usada em Tasks e Chat;
 *   • [CategoryFormSelector]— grade de seleção para formulários (nova tarefa /
 *                             novo assunto), onde uma categoria fica sempre
 *                             escolhida.
 * Assim todo lugar que mostra ou seleciona categoria fica visualmente idêntico.
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
          CategoryPill(
            label: 'Todos',
            isSelected: selectedCategoryId == null,
            semanticsPrefix: 'Filtrar por',
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final category in categories) ...[
            CategoryPill(
              label: category.label,
              icon: iconForCategory(category),
              color: colorForCategory(category),
              isSelected: selectedCategoryId == category.id,
              semanticsPrefix: 'Filtrar por',
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

/// Grade de seleção de categoria para formulários (nova tarefa, novo assunto).
///
/// Diferente do [CategoryChipSelector], não tem a opção "Todos" nem o botão de
/// gerenciar: aqui uma categoria fica **sempre** escolhida. Quebra em várias
/// linhas com [Wrap] para caber em modais estreitos.
class CategoryFormSelector extends StatelessWidget {
  const CategoryFormSelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  /// Categorias disponíveis, na ordem em que devem aparecer.
  final List<CareCategoryEntity> categories;

  /// Id da categoria atualmente escolhida.
  final String? selectedCategoryId;

  /// Disparado com o id da categoria tocada.
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final effectiveId = selectedCategoryId ?? categories.first.id;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((category) {
        return CategoryPill(
          label: category.label,
          icon: iconForCategory(category),
          color: colorForCategory(category),
          isSelected: effectiveId == category.id,
          semanticsPrefix: 'Selecionar categoria',
          onTap: () => onCategorySelected(category.id),
        );
      }).toList(),
    );
  }
}

/// Pílula de categoria reutilizável: cápsula arredondada com ícone opcional.
///
/// É a aparência única das categorias no app. Quando [isSelected] é `true`,
/// pinta com a [color] da categoria (ou `primary` como padrão) e ganha uma
/// sombra suave; caso contrário fica branca com borda.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
    this.semanticsPrefix,
  });

  /// Texto exibido na pílula.
  final String label;

  /// Se a pílula está marcada.
  final bool isSelected;

  /// Toque na pílula.
  final VoidCallback onTap;

  /// Ícone opcional antes do texto.
  final IconData? icon;

  /// Cor de destaque quando selecionada. Padrão: [AppColors.primary].
  final Color? color;

  /// Prefixo de acessibilidade (ex.: "Filtrar por", "Selecionar categoria").
  final String? semanticsPrefix;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsPrefix == null ? label : '$semanticsPrefix $label',
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
