/*
 * CareHub Plus — Widget Compartilhado / Botão de Voltar
 *
 * Seta de retorno padrão do app. Existe para que toda tela empilhada sobre
 * outra volte do mesmo jeito, com o mesmo ícone, a mesma área de toque e a
 * mesma leitura por leitor de tela — em vez de cada tela montar seu próprio
 * `IconButton`. Pensado para ir no `leading` do `AppHeader`.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Seta de voltar padrão do CareHub Plus.
///
/// Por padrão fecha a tela atual com `Navigator.maybePop`, que não quebra nada
/// quando não existe tela anterior na pilha (ex.: link direto).
///
/// ```dart
/// AppHeader(
///   showSettings: false,
///   leading: const AppBackButton(),
/// )
/// ```
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color = AppColors.textPrimary,
    this.tooltip = 'Voltar',
  });

  /// Ação do toque. Quando `null`, volta para a tela anterior.
  final VoidCallback? onPressed;

  /// Cor do ícone. Padrão: [AppColors.textPrimary].
  final Color color;

  /// Texto lido por leitores de tela e exibido no toque longo.
  final String tooltip;

  /// Lado da área de toque, mantido em 48px para atender ao mínimo de
  /// acessibilidade recomendado para alvos de toque.
  static const double _tapTargetSize = 48.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: Icon(Icons.arrow_back_rounded, color: color),
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: _tapTargetSize,
        minHeight: _tapTargetSize,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
    );
  }
}
