/*
 * CareHub Plus — Widget Compartilhado / Corpo Responsivo de Página
 *
 * Envelope padrão do conteúdo de todas as páginas. Resolve de uma vez:
 *   - padding horizontal/vertical que cresce com a tela;
 *   - largura máxima de leitura (evita conteúdo esticado em desktop/4K);
 *   - centralização do conteúdo em telas largas;
 *   - área segura (notch / barra inferior) e rolagem opcional.
 *
 * Author: Vitoria Lana
 * Created on: 13/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_responsive.dart';

/// Corpo padrão de uma página, já responsivo.
///
/// ```dart
/// AppResponsiveBody(
///   child: Column(children: [...]),
/// )
/// ```
class AppResponsiveBody extends StatelessWidget {
  const AppResponsiveBody({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
    this.maxWidth,
    this.applySafeArea = true,
    this.scrollController,
  });

  /// Conteúdo da página.
  final Widget child;

  /// Quando `true` (padrão), envolve o conteúdo em um scroll vertical.
  /// Use `false` quando o filho já rola sozinho (ex.: `ListView`).
  final bool scrollable;

  /// Sobrescreve o padding responsivo padrão.
  final EdgeInsetsGeometry? padding;

  /// Sobrescreve a largura máxima de conteúdo do breakpoint atual.
  final double? maxWidth;

  /// Aplica [SafeArea] nas laterais e na base (o topo costuma ser cuidado
  /// pelo `AppHeader`).
  final bool applySafeArea;

  /// Controller opcional para o scroll interno.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: context.pagePaddingHorizontal,
          vertical: context.pagePaddingVertical,
        );

    // Centraliza e limita a largura — em mobile o limite é infinito,
    // então o ConstrainedBox não altera nada.
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.contentMaxWidth,
        ),
        child: child,
      ),
    );

    content = Padding(padding: effectivePadding, child: content);

    if (scrollable) {
      content = SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    if (applySafeArea) {
      content = SafeArea(top: false, child: content);
    }

    return content;
  }
}
