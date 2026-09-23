/*
 * CareHub Plus — Widget Compartilhado / Gerenciar Categorias
 *
 * Bottom sheet para incluir e excluir categorias de cuidado. Espera um
 * `CareCategoriesBloc` já provido acima na árvore — Tasks e Chat abrem este
 * mesmo sheet, cada um com sua própria instância do BLoC apontando para o
 * mesmo repositório/coleção do Firestore.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/categories/domain/entities/care_category_entity.dart';
import '../../features/categories/presentation/bloc/care_categories_bloc.dart';
import '../../features/categories/presentation/models/category_visuals.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Mostra o gerenciador de categorias, reaproveitando o [CareCategoriesBloc]
/// já existente no contexto de quem chamou.
class ManageCategoriesBottomSheet extends StatelessWidget {
  const ManageCategoriesBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CareCategoriesBloc>(),
        child: const ManageCategoriesBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.radiusXl),
              topRight: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gerenciar Categorias',
                      style: AppTypography.averiaHeadlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Nova categoria',
                      onPressed: () => _CreateCategorySheet.show(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
                  builder: (context, state) {
                    if (state.status == CareCategoriesStatus.loading &&
                        state.categories.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (state.categories.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma categoria cadastrada ainda.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: state.categories.length,
                      itemBuilder: (context, index) {
                        final category = state.categories[index];
                        return _CategoryRow(
                          category: category,
                          isMutating: state.isMutating,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.isMutating});

  final CareCategoryEntity category;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(category);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconForCategory(category), color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              category.label,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (category.isDefault)
            Text(
              'Padrão',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Excluir categoria',
              onPressed: isMutating
                  ? null
                  : () => context.read<CareCategoriesBloc>().add(
                      CareCategoryDeleteEvent(categoryId: category.id),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Formulário curto de criação, aberto sobre o gerenciador.
class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CareCategoriesBloc>(),
        child: const _CreateCategorySheet(),
      ),
    );
  }

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  String _iconKey = categoryIcons.keys.first;
  String _colorKey = AppColors.categoryPalette.keys.first;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<CareCategoriesBloc>().add(
      CareCategoryAddEvent(
        label: _labelController.text.trim(),
        iconKey: _iconKey,
        colorKey: _colorKey,
      ),
    );
    // Não fecha aqui: espera a confirmação (ou o erro) do Firestore no
    // BlocListener abaixo. Fechar antes fazia a tela "aparentar sucesso"
    // mesmo quando a escrita era rejeitada — foi assim que uma falha de
    // permissão no Firestore ficou invisível para a usuária.
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<CareCategoriesBloc, CareCategoriesState>(
      listenWhen: (previous, current) =>
          previous.isMutating != current.isMutating ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage!,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          );
          return;
        }
        if (!state.isMutating) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXl),
            topRight: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nova Categoria',
                      style: AppTypography.averiaHeadlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _labelController,
                      label: 'Nome da categoria',
                      hint: 'Ex: Fisioterapia',
                      prefixIcon: Icons.label_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, informe um nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Ícone',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _IconPicker(
                      selectedKey: _iconKey,
                      onSelected: (key) => setState(() => _iconKey = key),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Cor',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ColorPicker(
                      selectedKey: _colorKey,
                      onSelected: (key) => setState(() => _colorKey = key),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Criar Categoria',
                      onPressed: () => _submit(context),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selectedKey, required this.onSelected});

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categoryIcons.entries.map((entry) {
        final isSelected = entry.key == selectedKey;
        return GestureDetector(
          onTap: () => onSelected(entry.key),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.value,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selectedKey, required this.onSelected});

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: AppColors.categoryPalette.entries.map((entry) {
        final isSelected = entry.key == selectedKey;
        return GestureDetector(
          onTap: () => onSelected(entry.key),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.textPrimary, width: 2)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
