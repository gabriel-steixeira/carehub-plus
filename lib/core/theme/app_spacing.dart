/// Spacing constants following a 4px grid system.
///
/// Never hardcode pixel values — always reference [AppSpacing].
class AppSpacing {
  AppSpacing._();

  // Spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;

  /// 12px — degrau intermediário do grid de 4px, entre [sm] e [md].
  static const double smMd = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;

  /// 10px — raio dos painéis tingidos do Figma (ver `AppTintedCard`).
  static const double radiusPanel = 10.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;
}
