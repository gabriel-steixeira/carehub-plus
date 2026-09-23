/*
 * CareHub Plus — Widget Compartilhado / Painel Tingido
 *
 * Tradução em Flutter do painel do Figma ("Category Header"): fundo colorido
 * translúcido, borda branca de 1px, sombra suave e canto de 10px. Todos os
 * painéis do app compartilham exatamente essa forma — apenas a cor de fundo
 * muda de tela para tela, informada em [tint].
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Painel tingido padrão do CareHub Plus.
///
/// A forma é fixa (padding, borda, sombra e raio vindos do Figma); só a cor
/// varia, o que mantém todos os painéis visualmente irmãos.
///
/// ```dart
/// AppTintedCard(
///   tint: AppColors.tintPink,
///   child: Text('Medicamentos', style: AppTypography.labelLarge),
/// )
/// ```
class AppTintedCard extends StatelessWidget {
  const AppTintedCard({
    super.key,
    required this.child,
    required this.tint,
    this.padding,
    this.margin,
  });

  /// Conteúdo do painel.
  final Widget child;

  /// Cor base do fundo. É aplicada com a opacidade padrão do design system,
  /// nunca em força total.
  final Color tint;

  /// Espaçamento interno. Padrão: 16px na horizontal e 12px na vertical.
  final EdgeInsetsGeometry? padding;

  /// Espaçamento externo. Padrão: nenhum.
  final EdgeInsetsGeometry? margin;

  /// Opacidade aplicada ao [tint]. Fixa de propósito: é o que garante que
  /// todos os painéis tenham o mesmo peso visual.
  static const double _tintOpacity = 0.3;

  /// Padding padrão do painel, conforme o Figma.
  static const EdgeInsets _defaultPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.smMd,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? _defaultPadding,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: _tintOpacity),
        border: Border.all(color: AppColors.background),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPanel),
        boxShadow: AppShadows.panel,
      ),
      child: child,
    );
  }
}
