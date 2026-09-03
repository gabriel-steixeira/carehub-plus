/*
 * CareHub Plus — SOS / Escolha de quem avisar
 *
 * Apresenta a rede de apoio em uma grade de avatares para que a cuidadora
 * reconheça rapidamente quem será avisado. A grade se reorganiza em novas
 * linhas conforme o espaço disponível e continua na rolagem da página.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../network/data/models/network_member_model.dart';

/// Seletor de quem da rede de apoio será avisado.
class SosNetworkPicker extends StatelessWidget {
  const SosNetworkPicker({
    super.key,
    required this.members,
    required this.notifiedMemberIds,
    required this.onMemberToggled,
    required this.onOpenNetwork,
  });

  /// Rede de apoio disponível.
  final List<NetworkMemberModel> members;

  /// Ids marcados para receber o alerta.
  final Set<String> notifiedMemberIds;

  /// Informa qual membro foi tocado (marca ou desmarca).
  final ValueChanged<String> onMemberToggled;

  /// Abre a tela de rede de apoio para cadastrar pessoas.
  final VoidCallback onOpenNetwork;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Column(
        children: [
          const AppEmptyView(
            message:
                'Sua rede de apoio está vazia.\n'
                'Cadastre alguém para poder pedir ajuda.',
            icon: Icons.group_add_rounded,
          ),
          AppButton(
            label: 'Abrir rede de apoio',
            variant: AppButtonVariant.secondary,
            icon: Icons.diversity_3_rounded,
            onPressed: onOpenNetwork,
          ),
        ],
      );
    }

    final isEveryoneSelected = notifiedMemberIds.length == members.length;
    final selectionLabel = isEveryoneSelected
        ? 'Todos'
        : '${notifiedMemberIds.length} selecionados';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Selecione quem você deseja alertar',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SelectionStatus(label: selectionLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.lg,
          children: [
            for (final member in members)
              _NetworkMemberAvatar(
                member: member,
                isSelected: notifiedMemberIds.contains(member.id),
                onTap: () => onMemberToggled(member.id),
              ),
            _AddNetworkMemberAction(onTap: onOpenNetwork),
          ],
        ),
      ],
    );
  }
}

/// Indicador somente de leitura da seleção atual da rede.
class _SelectionStatus extends StatelessWidget {
  const _SelectionStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}

/// Avatar selecionável de uma pessoa da rede de apoio.
class _NetworkMemberAvatar extends StatelessWidget {
  const _NetworkMemberAvatar({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final NetworkMemberModel member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${member.name}, ${isSelected ? 'selecionado' : 'não selecionado'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: SizedBox(
          width: AppSpacing.xxxl,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppMemberAvatar(
                    photo: member.photoUrl,
                    diameter: AppSpacing.xxxl,
                  ),
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: AppSpacing.md,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atalho visual para cadastrar mais pessoas na rede de apoio.
class _AddNetworkMemberAction extends StatelessWidget {
  const _AddNetworkMemberAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cadastrar nova pessoa na rede de apoio',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: SizedBox(
          width: AppSpacing.xxxl,
          child: Column(
            children: [
              Container(
                width: AppSpacing.xxxl,
                height: AppSpacing.xxxl,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: AppSpacing.xxl,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Novo',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
