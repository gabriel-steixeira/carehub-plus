/*
 * CareHub Plus — Perfil / Campo com Rótulo em Caixa Alta
 *
 * Envelope dos campos que não são de texto (data e gênero), para eles ficarem
 * idênticos ao `AppTextField` desta tela: mesmo rótulo em caixa alta, mesmo
 * espaço entre rótulo e campo e mesma altura de caixa.
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

/// Rótulo em caixa alta acima de um campo com borda.
class ProfileLabeledField extends StatelessWidget {
  const ProfileLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
  });

  /// Rótulo em caixa alta (ex.: "NASCIMENTO").
  final String label;

  /// Conteúdo dentro da caixa com borda.
  final Widget child;

  /// Quando informado, a caixa inteira responde ao toque.
  final VoidCallback? onTap;

  /// 56px — mesma altura que o `AppTextField` alcança com o padding padrão do
  /// design system. É o que mantém "NASCIMENTO" e "GÊNERO" alinhados na linha.
  static const double fieldHeight = AppSpacing.xxl + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(AppSpacing.radiusMd);

    Widget box = Container(
      height: fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: border,
      ),
      child: child,
    );

    if (onTap != null) {
      box = Material(
        color: Colors.transparent,
        borderRadius: border,
        child: InkWell(onTap: onTap, borderRadius: border, child: box),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.sectionLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        box,
      ],
    );
  }
}
