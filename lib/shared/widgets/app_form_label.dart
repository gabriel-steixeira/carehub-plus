/*
 * CareHub Plus — Widget Compartilhado / Rótulo de Campo de Formulário
 *
 * Rótulo de seção acima de um input (ex.: "Data", "Categoria"). Fonte única da
 * convenção (a) de rótulo do app: bodyMedium + textPrimary + peso médio,
 * seguido do espaço padrão até o campo. Não confundir com a convenção (b) de
 * rótulo em caixa alta (sectionLabel + textSecondary) usada por
 * ProfileLabeledField — essa fica intacta.
 *
 * Author: Vitoria Lana
 * Created on: 16/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Rótulo de seção acima de um input, no estilo padrão de formulário.
class AppFormLabel extends StatelessWidget {
  const AppFormLabel(
    this.text, {
    super.key,
    this.spacing = AppSpacing.sm,
  });

  /// Texto do rótulo (ex.: "Categoria").
  final String text;

  /// Espaço entre o rótulo e o campo abaixo. Padrão: [AppSpacing.sm].
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: spacing),
      ],
    );
  }
}
