/*
 * CareHub Plus — Design System / Responsividade
 *
 * Fornece as ferramentas para adaptar valores (fonte, espaçamento, padding,
 * quantidade de colunas, etc.) ao tamanho da tela atual:
 *   - [ResponsiveValue]  : um valor diferente por tipo de dispositivo.
 *   - [ResponsiveContext]: atalhos em cima do BuildContext.
 *
 * Author: Vitoria Lana
 * Created on: 13/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';
import 'app_spacing.dart';

/// Um valor que muda conforme o tipo de dispositivo.
///
/// Apenas [mobile] é obrigatório: os outros tamanhos fazem *fallback* em
/// cascata (ultraWide → desktop → tablet → mobile). Assim você declara só o
/// que realmente muda.
///
/// ```dart
/// const colunas = ResponsiveValue<int>(mobile: 1, tablet: 2, desktop: 4);
/// final total = colunas.resolve(context.deviceType);
/// ```
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
  });

  /// Valor base — obrigatório. Usado quando os demais não são informados.
  final T mobile;

  /// Valor para 451px – 800px.
  final T? tablet;

  /// Valor para 801px – 1920px.
  final T? desktop;

  /// Valor para 1921px+.
  final T? ultraWide;

  /// Resolve o valor final para o [device] informado.
  T resolve(DeviceType device) {
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
  }

  /// Resolve o valor final lendo o tamanho da tela direto do [context].
  T of(BuildContext context) => resolve(context.deviceType);
}

/// Atalhos responsivos em cima do [BuildContext].
///
/// Usa `MediaQuery.sizeOf(context)` em vez de `MediaQuery.of(context)`:
/// o widget passa a reconstruir apenas quando o *tamanho* muda, e não a cada
/// alteração de teclado, brilho ou padding do sistema.
extension ResponsiveContext on BuildContext {
  /// Largura atual da tela em pixels lógicos.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Altura atual da tela em pixels lógicos.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Tipo de dispositivo derivado da largura atual.
  DeviceType get deviceType => AppBreakpoints.fromWidth(screenWidth);

  // ---------------------------------------------------------------------------
  // CONDICIONAIS
  // ---------------------------------------------------------------------------

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isUltraWide => deviceType == DeviceType.ultraWide;

  /// `true` para tablet ou maior — útil para decidir entre layout de coluna
  /// única e layout de múltiplas colunas.
  bool get isTabletOrLarger => screenWidth > AppBreakpoints.mobileMax;

  /// `true` para desktop ou maior.
  bool get isDesktopOrLarger => screenWidth > AppBreakpoints.tabletMax;

  /// `true` quando a tela está em orientação paisagem.
  bool get isLandscape => screenWidth > screenHeight;

  // ---------------------------------------------------------------------------
  // VALORES DINÂMICOS
  // ---------------------------------------------------------------------------

  /// Escolhe um valor por tipo de dispositivo, sem instanciar [ResponsiveValue].
  ///
  /// ```dart
  /// final colunas = context.responsive<int>(mobile: 1, tablet: 2, desktop: 4);
  /// ```
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? ultraWide,
  }) {
    return ResponsiveValue<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      ultraWide: ultraWide,
    ).resolve(deviceType);
  }

  /// Largura máxima de conteúdo para a tela atual.
  double get contentMaxWidth => AppBreakpoints.contentMaxWidth(deviceType);

  /// Padding horizontal padrão das páginas, já adaptado à tela.
  double get pagePaddingHorizontal => responsive<double>(
        mobile: AppSpacing.md,
        tablet: AppSpacing.lg,
        desktop: AppSpacing.xl,
        ultraWide: AppSpacing.xxl,
      );

  /// Padding vertical padrão das páginas, já adaptado à tela.
  double get pagePaddingVertical => responsive<double>(
        mobile: AppSpacing.sm,
        tablet: AppSpacing.md,
        desktop: AppSpacing.lg,
      );

  /// Espaçamento entre seções de uma página, já adaptado à tela.
  double get sectionSpacing => responsive<double>(
        mobile: AppSpacing.md,
        tablet: AppSpacing.lg,
        desktop: AppSpacing.xl,
      );

  /// Fator multiplicador de fonte por dispositivo.
  ///
  /// Mantém 1.0 no mobile (o design do Figma é mobile-first) e cresce de forma
  /// contida nas telas maiores.
  double get fontScale => responsive<double>(
        mobile: 1.0,
        tablet: 1.05,
        desktop: 1.1,
        ultraWide: 1.2,
      );

  /// Aplica [fontScale] a um tamanho de fonte base do design system.
  ///
  /// ```dart
  /// AppTypography.titleLarge.copyWith(fontSize: context.scaleFont(18));
  /// ```
  double scaleFont(double baseSize) => baseSize * fontScale;

  /// Fator multiplicador de espaçamento por dispositivo.
  ///
  /// Mantém 1.0 no mobile (o design do Figma é mobile-first) e cresce de forma
  /// contida nas telas maiores, no mesmo espírito de [fontScale].
  double get spacingScale => responsive<double>(
        mobile: 1.0,
        tablet: 1.05,
        desktop: 1.1,
        ultraWide: 1.2,
      );

  /// Aplica [spacingScale] a um espaçamento base do design system.
  ///
  /// Use para manter uma proporção de espaço estável entre dispositivos,
  /// em vez de fixar um valor em pixels.
  ///
  /// ```dart
  /// SizedBox(height: context.scaleSpacing(AppSpacing.lg));
  /// ```
  double scaleSpacing(double baseSpacing) => baseSpacing * spacingScale;
}
