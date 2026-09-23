/*
 * CareHub Plus — Apresentação / Indicador de "Analisando"
 *
 * Bolha temporária exibida enquanto o assistente prepara a resposta. Dá
 * retorno imediato à cuidadora, para que a espera não pareça travamento.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_chat_avatar.dart';

/// Bolha de "digitando" do assistente.
class AssistantThinkingIndicator extends StatelessWidget {
  const AssistantThinkingIndicator({
    super.key,
    required this.avatarAsset,
    required this.label,
    this.accentColor = AppColors.primary,
  });

  /// Avatar do agente que está pensando.
  final String avatarAsset;

  /// Texto de espera, vindo do `AssistantProfile`.
  final String label;

  /// Cor do indicador de atividade.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          AppChatAvatar.asset(assetPath: avatarAsset),
          const SizedBox(width: AppSpacing.xs),
          // Flexible nas duas pontas: com fonte ampliada por acessibilidade ou
          // tela estreita, o texto quebra em vez de estourar a linha.
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.raised,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppSpacing.smMd,
                    height: AppSpacing.smMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.scaleFont(12),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
