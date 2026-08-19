/*
 * CareHub Plus — Chat / Controles de filtros
 *
 * Reúne os filtros de perfil, assunto e ordenação da lista de conversas para
 * manter a página de Chat focada apenas em compor o estado da tela.
 *
 * Author: Vitoria Lana
 * Created on: 16/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/chat_bloc.dart';

/// Exibe a seleção do perfil de cuidado a que os assuntos pertencem.
class ChatProfileFilterSection extends StatelessWidget {
  const ChatProfileFilterSection({
    super.key,
    required this.profiles,
    required this.selectedProfileName,
    required this.onProfileSelected,
    required this.onAddProfile,
  });

  final Map<String, String?> profiles;
  final String? selectedProfileName;
  final ValueChanged<String?> onProfileSelected;
  final VoidCallback onAddProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtrar por perfil',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _ProfileChip(
                label: 'Todos',
                isSelected: selectedProfileName == null,
                onTap: () => onProfileSelected(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              ...profiles.entries.expand(
                (entry) => [
                  _ProfileChip(
                    label: entry.key,
                    photoUrl: entry.value,
                    isSelected: entry.key == selectedProfileName,
                    onTap: () => onProfileSelected(entry.key),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              _AddProfileButton(onTap: onAddProfile),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.photoUrl,
  });

  final String label;
  final String? photoUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? AppColors.textInverse
        : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filtrar por $label',
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: isSelected
                  ? AppShadows.accent(AppColors.primary)
                  : AppShadows.raised,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photoUrl != null) ...[
                  CircleAvatar(
                    radius: AppSpacing.sm,
                    backgroundImage: NetworkImage(photoUrl!),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProfileButton extends StatelessWidget {
  const _AddProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Adicionar perfil',
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Icon(Icons.add, color: AppColors.textInverse),
          ),
        ),
      ),
    );
  }
}

/// Agrupa os filtros de assunto e o seletor de ordenação.
class ChatTopicFilterSection extends StatelessWidget {
  const ChatTopicFilterSection({
    super.key,
    required this.selectedCategory,
    required this.sortOption,
    required this.onCategorySelected,
    required this.onSortSelected,
  });

  final ChatCategory? selectedCategory;
  final ChatSortOption sortOption;
  final ValueChanged<ChatCategory?> onCategorySelected;
  final ValueChanged<ChatSortOption> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assuntos',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _TopicFilterChip(
                label: 'Todos',
                isSelected: selectedCategory == null,
                onTap: () => onCategorySelected(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TopicFilterChip(
                label: 'Saúde',
                icon: Icons.medication_outlined,
                isSelected: selectedCategory == ChatCategory.health,
                onTap: () => onCategorySelected(ChatCategory.health),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TopicFilterChip(
                label: 'Alimentação',
                icon: Icons.restaurant_outlined,
                isSelected: selectedCategory == ChatCategory.food,
                onTap: () => onCategorySelected(ChatCategory.food),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<ChatSortOption>(
            initialValue: sortOption,
            onSelected: onSortSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ChatSortOption.recent,
                child: Text('Recentes'),
              ),
              PopupMenuItem(
                value: ChatSortOption.alphabetical,
                child: Text('A–Z'),
              ),
              PopupMenuItem(
                value: ChatSortOption.unread,
                child: Text('Não lidos'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: AppShadows.raised,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Ordenar por: ${_sortLabel(sortOption)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _sortLabel(ChatSortOption option) => switch (option) {
    ChatSortOption.recent => 'Recentes',
    ChatSortOption.alphabetical => 'A–Z',
    ChatSortOption.unread => 'Não lidos',
  };
}

class _TopicFilterChip extends StatelessWidget {
  const _TopicFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? AppColors.textInverse
        : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filtrar assuntos por $label',
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.md, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
