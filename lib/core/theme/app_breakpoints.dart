/*
 * CareHub Plus — Design System / Breakpoints Responsivos
 *
 * Define os limites de largura (breakpoints) que classificam a tela atual
 * em um tipo de dispositivo, além das larguras máximas de conteúdo usadas
 * para evitar que o layout "esticue" em telas grandes.
 *
 * Author: Vitoria Lana
 * Created on: 13/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

/// Tipos de dispositivo suportados pelo app.
///
/// A classificação é feita pela largura da tela (e não pelo sistema
/// operacional), então um celular na horizontal pode ser tratado como
/// [DeviceType.tablet] — que é o comportamento correto para layout.
enum DeviceType {
  /// 0px – 450px — celulares.
  mobile,

  /// 451px – 800px — tablets e phablets.
  tablet,

  /// 801px – 1920px — desktops e notebooks.
  desktop,

  /// 1921px+ — telas 4K e ultrawide.
  ultraWide,
}

/// Limites de largura do design system.
///
/// Nunca compare larguras com números soltos no meio do código.
/// Sempre use [AppBreakpoints] ou a extension `context.deviceType`.
class AppBreakpoints {
  AppBreakpoints._();

  // ---------------------------------------------------------------------------
  // LIMITES (valores máximos, em pixels lógicos)
  // ---------------------------------------------------------------------------

  /// Limite superior de mobile (inclusive).
  static const double mobileMax = 450.0;

  /// Limite superior de tablet (inclusive).
  static const double tabletMax = 800.0;

  /// Limite superior de desktop (inclusive). Acima disso é [DeviceType.ultraWide].
  static const double desktopMax = 1920.0;

  // ---------------------------------------------------------------------------
  // LARGURA MÁXIMA DE CONTEÚDO
  // ---------------------------------------------------------------------------
  // Em telas largas, texto ocupando 100% da largura fica ilegível.
  // Estes valores limitam e centralizam o conteúdo.

  static const double contentMaxWidthMobile = double.infinity;
  static const double contentMaxWidthTablet = 720.0;
  static const double contentMaxWidthDesktop = 1140.0;
  static const double contentMaxWidthUltraWide = 1440.0;

  /// Classifica uma [width] em um [DeviceType].
  static DeviceType fromWidth(double width) {
    if (width <= mobileMax) return DeviceType.mobile;
    if (width <= tabletMax) return DeviceType.tablet;
    if (width <= desktopMax) return DeviceType.desktop;
    return DeviceType.ultraWide;
  }

  /// Largura máxima de conteúdo recomendada para cada [DeviceType].
  static double contentMaxWidth(DeviceType device) {
    switch (device) {
      case DeviceType.mobile:
        return contentMaxWidthMobile;
      case DeviceType.tablet:
        return contentMaxWidthTablet;
      case DeviceType.desktop:
        return contentMaxWidthDesktop;
      case DeviceType.ultraWide:
        return contentMaxWidthUltraWide;
    }
  }
}
