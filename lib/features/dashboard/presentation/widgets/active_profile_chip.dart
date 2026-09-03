/*
 * CareHub Plus — Dashboard / Active Profile Chip
 *
 * Chip de identificação do perfil cuidado atualmente selecionado. Exibe
 * avatar, nome e um ícone de troca que navega de volta à Home (seleção de
 * perfil). É um affordance — deixa claro qual perfil está ativo e oferece
 * a troca sem exigir um seletor completo na tela.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/data/models/care_recipient_model.dart';

/// Chip que identifica o perfil cuidado ativo e oferece a troca de perfil.
///
/// Widget puramente presentacional — recebe o perfil e callbacks, sem acessar
/// BLoC ou repositório diretamente.
class ActiveProfileChip extends StatelessWidget {
  const ActiveProfileChip({
    super.key,
    required this.profile,
    required this.onChangeTap,
  });

  /// Perfil cuidado atualmente selecionado.
  final CareRecipientModel profile;

  /// Chamado quando o usuário toca no botão de troca de perfil.
  final VoidCallback onChangeTap;

  /// Tenta base64 primeiro (foto da galeria), depois URL (foto de rede).
  /// Retorna null quando não há nenhuma foto — o ícone genérico é exibido.
  ImageProvider? _buildAvatarImage(CareRecipientModel profile) {
    if (profile.photoBase64 != null) {
      final raw = profile.photoBase64!;
      final base64Str = raw.contains(',') ? raw.split(',').last : raw;
      try {
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        // base64 inválido — cai para URL ou ícone
      }
    }
    if (profile.photoUrl != null) {
      return NetworkImage(profile.photoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Chip do perfil ativo
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar do perfil — tenta base64 primeiro, depois URL
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: _buildAvatarImage(profile),
                  child: _buildAvatarImage(profile) == null
                      ? Icon(
                          profile.type == 'pet'
                              ? Icons.pets
                              : Icons.person_outline,
                          size: 14,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Nome e label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cuidando de',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Botão de troca de perfil
        Tooltip(
          message: 'Trocar perfil',
          child: GestureDetector(
            onTap: onChangeTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Symbols.patient_list,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
