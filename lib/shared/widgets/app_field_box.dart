/*
 * CareHub Plus — Widget Compartilhado / Caixa de Campo com Borda
 *
 * Caixa transparente com borda arredondada e padding padrão, opcionalmente
 * tocável, usada em campos de "entrada manual" (data, horário) dimensionados
 * pelo conteúdo. Variante transparente — não confundir com ProfileLabeledField,
 * que tem altura fixa de 56px e fundo preenchido.
 *
 * Author: Vitoria Lana
 * Created on: 16/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Caixa com borda arredondada, opcionalmente tocável, dimensionada pelo filho.
class AppFieldBox extends StatelessWidget {
  const AppFieldBox({
    super.key,
    required this.child,
    this.onTap,
  });

  /// Conteúdo da caixa (ex.: ícone + texto).
  final Widget child;

  /// Quando informado, a caixa inteira responde ao toque.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: child,
    );

    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}
