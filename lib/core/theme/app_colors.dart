import 'package:flutter/material.dart';

/// Color palette — SINGLE SOURCE OF TRUTH for all colors.
///
/// Never hardcode [Color(0xFF...)] anywhere except in this file.
class AppColors {
  AppColors._();

  // PRIMARY
  static const Color primary = Color(0xFF7B61C8);
  static const Color primaryLight = Color(0xFFAF9EE0);
  static const Color primaryDark = Color(0xFF5A44A8);

  // BACKGROUND & SURFACES
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F6FF);
  static const Color surfaceVariant = Color(0xFFF0ECFD);

  // GRADIENT (Figma: purple → white → pink)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BDB), Color(0xFFFFFFFF), Color(0xFFFACFE8)],
    stops: [0.09, 0.57, 1.0],
  );

  // Splash/Auth background gradient (vertical, lilac top → pink-white bottom)
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8DFFA),
      Color(0xFFF3EEFF),
      Color(0xFFFDF6FA),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  // Progress bar gradient (purple → blue → green → pink)
  static const Color progressBlue = Color(0xFF80C4FF);
  static const Color progressGreen = Color(0xFFA5F3A5);
  static const Color progressPink = Color(0xFFFACFE8);

  static const LinearGradient progressBarGradient = LinearGradient(
    colors: [primary, progressBlue, progressGreen, progressPink],
  );

  // TEXT
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B8A);
  static const Color textHint = Color(0xFFB0B0C8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // FEEDBACK
  static const Color success = Color(0xFF437A22);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF006494);

  // DIVIDER / BORDER
  static const Color divider = Color(0xFFE8E4F7);
  static const Color border = Color(0xFFD4CEEF);
}
