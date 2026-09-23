/*
 * CareHub Plus — SOS / Linha de membro da rede de apoio
 *
 * Identificação de uma pessoa da rede de apoio (foto, nome e papel ou situação)
 * usada em todas as etapas do SOS: escolher quem avisar, ver quem foi avisado e
 * mostrar quem aceitou o chamado. Só desenha o que recebe.
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
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../network/data/models/network_member_model.dart';

/// Linha com foto, nome e legenda de um membro da rede de apoio.
class SosMemberTile extends StatelessWidget {
  const SosMemberTile({
    super.key,
    required this.member,
    this.statusLabel,
    this.statusColor,
  });

  /// Membro exibido.
  final NetworkMemberModel member;

  /// Legenda abaixo do nome. Quando `null`, mostra o papel do membro.
  final String? statusLabel;

  /// Cor da legenda. Quando `null`, usa o texto secundário.
  final Color? statusColor;

  static const double _avatarRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppMemberAvatar(photo: member.photoUrl, diameter: _avatarRadius * 2),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                statusLabel ?? member.role.label,
                style: AppTypography.labelSmall.copyWith(
                  color: statusColor ?? AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
