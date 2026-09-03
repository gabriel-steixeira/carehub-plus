/*
 * CareHub Plus — Widget Compartilhado / Fade de Rolagem
 *
 * Suaviza as bordas de uma área rolável. Sem ele, o conteúdo é cortado em
 * linha reta no limite do scroll e parece "colar" no elemento vizinho — como
 * acontecia entre as mensagens da Cora e o cartão de identidade. Aqui o
 * conteúdo se dissolve no fundo, indicando que há mais coisa para rolar.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Aplica um degradê de transparência nas bordas de um conteúdo rolável.
///
/// O fade é puramente visual: não intercepta toques nem altera o scroll.
///
/// ```dart
/// AppScrollFade(
///   child: ListView.builder(...),
/// )
/// ```
class AppScrollFade extends StatelessWidget {
  const AppScrollFade({
    super.key,
    required this.child,
    this.topExtent = AppSpacing.lg,
    this.bottomExtent = AppSpacing.md,
  });

  /// Conteúdo rolável que recebe o fade.
  final Widget child;

  /// Altura do fade na borda superior. Zero desliga o efeito.
  final double topExtent;

  /// Altura do fade na borda inferior. Zero desliga o efeito.
  final double bottomExtent;

  @override
  Widget build(BuildContext context) {
    if (topExtent <= 0 && bottomExtent <= 0) return child;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: _buildShader,
      child: child,
    );
  }

  /// Monta a máscara de opacidade: transparente nas bordas, opaca no meio.
  Shader _buildShader(Rect bounds) {
    final height = bounds.height;

    // Em alturas muito pequenas o fade consumiria o conteúdo inteiro.
    if (height <= 0) {
      return const LinearGradient(
        colors: [Colors.black, Colors.black],
      ).createShader(bounds);
    }

    final topStop = (topExtent / height).clamp(0.0, 0.5);
    final bottomStop = (bottomExtent / height).clamp(0.0, 0.5);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Colors.transparent,
        Colors.black,
        Colors.black,
        Colors.transparent,
      ],
      stops: [0, topStop, 1 - bottomStop, 1],
    ).createShader(bounds);
  }
}
