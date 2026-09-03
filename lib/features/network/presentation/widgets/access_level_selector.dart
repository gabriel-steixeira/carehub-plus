/*
 * CareHub Plus — Network / AccessLevelSelector widget
 *
 * Seletor do nível de acesso de um membro da rede de apoio em cartões
 * descritivos. Cada opção mostra ícone, título e uma explicação do que o
 * membro poderá fazer; a opção "Acesso Parcial" revela os chips das permissões
 * específicas, para a cuidadora entender a escolha antes de confirmar.
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
import '../../data/models/network_member_model.dart';

/// Aparência de cada nível de acesso (ícone e cores do avatar do cartão).
typedef _AccessLevelVisuals = ({
  Color background,
  Color foreground,
  IconData icon,
});

/// Lista de cartões de nível de acesso, um selecionável por vez.
///
/// Não decide nada sobre o membro: apenas renderiza o que recebe e avisa o
/// formulário quando a cuidadora toca em uma opção ou em uma permissão.
class AccessLevelSelector extends StatelessWidget {
  const AccessLevelSelector({
    super.key,
    required this.accessLevel,
    required this.permissions,
    required this.onAccessLevelChanged,
    required this.onPermissionToggled,
    this.label = 'Nível de Acesso',
    this.errorText,
  });

  /// Nível atualmente selecionado.
  final AccessLevel accessLevel;

  /// Permissões marcadas — só usadas quando [accessLevel] é
  /// [AccessLevel.partial].
  final Set<NetworkPermission> permissions;

  /// Disparado com o nível tocado.
  final ValueChanged<AccessLevel> onAccessLevelChanged;

  /// Disparado com a permissão tocada (marcar ou desmarcar).
  final ValueChanged<NetworkPermission> onPermissionToggled;

  /// Rótulo da seção.
  final String label;

  /// Mensagem de erro exibida abaixo dos chips, quando houver.
  final String? errorText;

  /// Ordem de exibição dos cartões — do acesso mais restrito ao mais amplo.
  static const List<AccessLevel> _displayOrder = [
    AccessLevel.partial,
    AccessLevel.readonly,
    AccessLevel.full,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final level in _displayOrder) ...[
          _AccessLevelCard(
            level: level,
            isSelected: level == accessLevel,
            permissions: permissions,
            onTap: () => onAccessLevelChanged(level),
            onPermissionToggled: onPermissionToggled,
            errorText: errorText,
          ),
          if (level != _displayOrder.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets internos (privados ao arquivo)
// ─────────────────────────────────────────────────────────────────────────────

/// Cartão de uma opção de nível de acesso.
class _AccessLevelCard extends StatelessWidget {
  const _AccessLevelCard({
    required this.level,
    required this.isSelected,
    required this.permissions,
    required this.onTap,
    required this.onPermissionToggled,
    this.errorText,
  });

  final AccessLevel level;
  final bool isSelected;
  final Set<NetworkPermission> permissions;
  final VoidCallback onTap;
  final ValueChanged<NetworkPermission> onPermissionToggled;
  final String? errorText;

  /// Os chips de permissão só existem no "Acesso Parcial" selecionado.
  bool get _showsPermissions =>
      isSelected && level == AccessLevel.partial;

  _AccessLevelVisuals get _visuals => switch (level) {
        AccessLevel.partial => (
            background: AppColors.warning.withValues(alpha: 0.15),
            foreground: AppColors.warning,
            icon: Icons.tune_rounded,
          ),
        AccessLevel.readonly => (
            background: AppColors.info.withValues(alpha: 0.15),
            foreground: AppColors.info,
            icon: Icons.visibility_outlined,
          ),
        AccessLevel.full => (
            background: AppColors.primary,
            foreground: AppColors.textInverse,
            icon: Icons.lock_outline_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final visuals = _visuals;

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: '${level.label}. ${level.description}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.smMd),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar do nível ──────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visuals.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  visuals.icon,
                  size: 20,
                  color: visuals.foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),

              // ── Título, explicação e chips ───────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      level.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_showsPermissions) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PermissionChips(
                        permissions: permissions,
                        onToggled: onPermissionToggled,
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          errorText!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── Marcador de seleção ──────────────────────────────────
              _SelectionIndicator(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo de seleção à direita do cartão.
class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return const Icon(
        Icons.check_circle_rounded,
        size: 22,
        color: AppColors.primary,
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );
  }
}

/// Fileira de chips das permissões específicas do "Acesso Parcial".
class _PermissionChips extends StatelessWidget {
  const _PermissionChips({
    required this.permissions,
    required this.onToggled,
  });

  final Set<NetworkPermission> permissions;
  final ValueChanged<NetworkPermission> onToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final permission in NetworkPermission.values)
          _PermissionChip(
            permission: permission,
            isSelected: permissions.contains(permission),
            onTap: () => onToggled(permission),
          ),
      ],
    );
  }
}

/// Chip individual de permissão, marcável e desmarcável.
class _PermissionChip extends StatelessWidget {
  const _PermissionChip({
    required this.permission,
    required this.isSelected,
    required this.onTap,
  });

  final NetworkPermission permission;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Permissão ${permission.label}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.smMd,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            permission.label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected
                  ? AppColors.textInverse
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
