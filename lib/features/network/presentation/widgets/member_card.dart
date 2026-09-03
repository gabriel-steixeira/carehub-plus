/*
 * CareHub Plus — Network / MemberCard widget
 *
 * Card de membro da rede de apoio. Exibe avatar, nome, relacionamento,
 * tipo de contato, nível de acesso e ações de editar e remover.
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
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../data/models/network_member_model.dart';

/// Card de exibição de um membro da rede de apoio.
///
/// Mostra avatar, nome, "Relacionamento • Tipo", badge de nível de acesso
/// e os botões de editar e remover.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.onRemove,
    this.onEdit,
  });

  final NetworkMemberModel member;
  final VoidCallback onRemove;

  /// Callback opcional para abrir o formulário de edição.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          _MemberAvatar(member: member),
          const SizedBox(width: AppSpacing.md),

          // ── Dados do membro ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                Text(
                  member.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),

                // "Filha • Principal"
                _RelationshipRow(member: member),
                const SizedBox(height: AppSpacing.xs),

                // Badge de acesso
                _AccessBadge(accessLevel: member.accessLevel),
              ],
            ),
          ),

          // ── Ações ────────────────────────────────────────────────────────
          _ActionButtons(onEdit: onEdit, onRemove: onRemove),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets internos (privados ao arquivo)
// ─────────────────────────────────────────────────────────────────────────────

/// Avatar circular com badge de online opcional.
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final NetworkMemberModel member;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppMemberAvatar(photo: member.photoUrl, diameter: 52),
        if (member.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Linha com "Relacionamento • Tipo" (ex: "Filha • Principal").
class _RelationshipRow extends StatelessWidget {
  const _RelationshipRow({required this.member});

  final NetworkMemberModel member;

  @override
  Widget build(BuildContext context) {
    // Monta o texto combinando relacionamento (se existir) com o tipo do membro.
    final parts = <String>[
      if (member.relationship != null && member.relationship!.isNotEmpty)
        member.relationship!,
      member.memberType.label,
    ];

    return Text(
      parts.join(' • '),
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }
}

/// Pill com ícone e label do nível de acesso.
class _AccessBadge extends StatelessWidget {
  const _AccessBadge({required this.accessLevel});

  final AccessLevel accessLevel;

  @override
  Widget build(BuildContext context) {
    final (
      Color badgeColor,
      Color textColor,
      IconData icon,
    ) = switch (accessLevel) {
      AccessLevel.full => (
        AppColors.primary.withValues(alpha: 0.12),
        AppColors.primaryDark,
        Icons.tune_rounded,
      ),
      AccessLevel.partial => (
        AppColors.info.withValues(alpha: 0.12),
        AppColors.info,
        Icons.tune_rounded,
      ),
      AccessLevel.readonly => (
        AppColors.warning.withValues(alpha: 0.12),
        AppColors.warning,
        Icons.visibility_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            accessLevel.label,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botões de editar e remover alinhados horizontalmente.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onRemove, this.onEdit});

  final VoidCallback? onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Editar
        _IconAction(
          icon: Icons.edit_outlined,
          color: AppColors.textSecondary,
          onTap: onEdit ?? () {},
          tooltip: 'Editar',
        ),
        const SizedBox(width: AppSpacing.xs),
        // Remover
        _IconAction(
          icon: Icons.delete_outline_rounded,
          color: AppColors.textSecondary,
          onTap: onRemove,
          tooltip: 'Remover',
        ),
      ],
    );
  }
}

/// Botão de ícone simples com área de toque generosa.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
