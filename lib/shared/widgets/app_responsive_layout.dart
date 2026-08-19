/*
 * CareHub Plus — Widget Compartilhado / Layout Responsivo
 *
 * Escolhe qual árvore de widgets construir de acordo com o tipo de
 * dispositivo. Use quando o layout muda de ESTRUTURA (ex.: lista única no
 * celular x grade de duas colunas no tablet). Para mudar apenas VALORES
 * (fonte, padding, colunas), prefira `context.responsive(...)`.
 *
 * Author: Vitoria Lana
 * Created on: 13/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';

/// Constrói um layout diferente por tipo de dispositivo.
///
/// Só [mobile] é obrigatório. Os demais fazem *fallback* em cascata
/// (ultraWide → desktop → tablet → mobile).
///
/// ```dart
/// AppResponsiveLayout(
///   mobile: TasksListView(),
///   tablet: TasksGridView(columns: 2),
///   desktop: TasksGridView(columns: 3),
/// )
/// ```
///
/// Usa [LayoutBuilder]: a decisão considera o espaço disponível para ESTE
/// widget, não a tela inteira. Isso mantém o componente correto mesmo dentro
/// de um painel lateral estreito.
class AppResponsiveLayout extends StatelessWidget {
  const AppResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
  });

  /// Layout base (0px – 450px). Obrigatório.
  final Widget mobile;

  /// Layout para 451px – 800px.
  final Widget? tablet;

  /// Layout para 801px – 1920px.
  final Widget? desktop;

  /// Layout para 1921px+.
  final Widget? ultraWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = AppBreakpoints.fromWidth(constraints.maxWidth);

        switch (device) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.ultraWide:
            return ultraWide ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}
