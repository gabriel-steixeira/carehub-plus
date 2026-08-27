/*
 * CareHub Plus — Design System / Elevação e Sombras
 *
 * Tokens de sombra do design system. Separar elevação de cor é prática padrão
 * de design system: uma sombra é composta de cor + desfoque + deslocamento,
 * então não cabe em `AppColors`.
 *
 * Author: Vitoria Lana
 * Created on: 13/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

/// Sombras padronizadas do app.
///
/// Nunca declare `BoxShadow` solto em um widget — use um destes tokens.
class AppShadows {
  AppShadows._();

  /// Preto a 8% — base de todas as sombras neutras.
  static const Color _neutral08 = Color(0x14000000);

  /// Preto a 4% — sombras muito discretas.
  static const Color _neutral04 = Color(0x0A000000);

  /// Cartões padrão (`AppCard`). Sombra rasa, quase imperceptível.
  static const List<BoxShadow> card = [
    BoxShadow(color: _neutral08, blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Elementos suspensos: barras de busca, chips de filtro.
  static const List<BoxShadow> raised = [
    BoxShadow(color: _neutral04, blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Preto a 7% — sombra dos painéis tingidos do Figma.
  static const Color _neutral07 = Color(0x12000000);

  /// Painéis tingidos (`AppTintedCard`): faixas e cabeçalhos de seção.
  static const List<BoxShadow> panel = [
    BoxShadow(color: _neutral07, blurRadius: 2, offset: Offset(0, 2)),
  ];

  /// Modais e bottom sheets.
  static const List<BoxShadow> overlay = [
    BoxShadow(color: _neutral08, blurRadius: 16, offset: Offset(0, -2)),
  ];

  /// Sombra colorida para elementos de destaque na cor primária.
  ///
  /// Recebe a cor por parâmetro para não duplicar a paleta aqui —
  /// passe `AppColors.primary` no ponto de uso.
  static List<BoxShadow> accent(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];
}
