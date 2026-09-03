/*
 * CareHub Plus — Widget Compartilhado / Card Padrão
 *
 * Cartão base do design system: fundo branco, canto arredondado (radiusMd) e
 * sombra suave. Substitui o padrão repetido de Container + BoxDecoration
 * espalhado pelas telas, garantindo que todo cartão do app seja idêntico.
 *
 * Author: Vitoria Lana
 * Created on: 13/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Variações visuais do [AppCard].
enum AppCardVariant {
  /// Fundo branco + sombra suave. Padrão do design system.
  elevated,

  /// Fundo branco + borda, sem sombra. Para listas densas.
  outlined,

  /// Fundo lilás claro (`surfaceVariant`), sem sombra. Para blocos de destaque.
  filled,
}

/// Cartão padrão do CareHub Plus.
///
/// ```dart
/// AppCard(
///   onTap: () => context.push(AppRoutes.tasks),
///   child: Text('Tarefas de hoje', style: AppTypography.titleMedium),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.width,
  });

  /// Conteúdo do cartão.
  final Widget child;

  /// Estilo visual. Padrão: [AppCardVariant.elevated].
  final AppCardVariant variant;

  /// Espaçamento interno. Padrão: `AppSpacing.md`.
  final EdgeInsetsGeometry? padding;

  /// Espaçamento externo. Padrão: nenhum.
  final EdgeInsetsGeometry? margin;

  /// Raio das bordas. Padrão: `AppSpacing.radiusMd`.
  final double? borderRadius;

  /// Quando informado, o cartão fica clicável com efeito de toque (ripple).
  final VoidCallback? onTap;

  /// Largura fixa opcional. Por padrão o cartão acompanha o pai.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    // InkWell precisa ficar DENTRO do Material para o ripple ser recortado
    // pelo mesmo raio do cartão.
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: radius,
        border: variant == AppCardVariant.outlined
            ? Border.all(color: AppColors.border)
            : null,
        boxShadow:
            variant == AppCardVariant.elevated ? AppShadows.card : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: content,
      ),
    );
  }

  Color get _backgroundColor {
    switch (variant) {
      case AppCardVariant.elevated:
      case AppCardVariant.outlined:
        return AppColors.background;
      case AppCardVariant.filled:
        return AppColors.surfaceVariant;
    }
  }
}
