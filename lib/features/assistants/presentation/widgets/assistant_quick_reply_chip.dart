/*
 * CareHub Plus — Apresentação / Chip de Resposta Rápida
 *
 * Atalho sugerido pelo assistente. O widget só exibe o rótulo e devolve a
 * sugestão inteira no toque — quem decide o que fazer com a intenção é o BLoC.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';

/// Chip clicável com uma sugestão de conversa.
class AssistantQuickReplyChip extends StatelessWidget {
  const AssistantQuickReplyChip({
    super.key,
    required this.quickReply,
    required this.onTap,
    this.accentColor,
  });

  /// Sugestão exibida.
  final AssistantQuickReply quickReply;

  /// Disparado no toque, já com a sugestão completa.
  final ValueChanged<AssistantQuickReply> onTap;

  /// Cor opcional da identidade do assistente.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => onTap(quickReply),
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: accentColor ?? AppColors.primaryLight,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      avatar: Icon(
        Icons.auto_awesome_outlined,
        size: AppSpacing.smMd,
        color: accentColor ?? AppColors.primary,
      ),
      label: Text(
        quickReply.label,
        style: AppTypography.labelSmall.copyWith(
          color: accentColor ?? AppColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: context.scaleFont(12),
        ),
      ),
    );
  }
}
