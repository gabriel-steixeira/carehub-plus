import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system using Inter for body text and Averia Sans Libre for optional titles.
///
/// Never use raw [TextStyle(...)] inline in widgets.
class AppTypography {
  AppTypography._();

  static String get _fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  static String get _titleFontFamily =>
      GoogleFonts.averiaSansLibre().fontFamily ?? 'Averia Sans Libre';

  static TextStyle _withTitleFont(TextStyle textStyle) =>
      textStyle.copyWith(fontFamily: _titleFontFamily);

  // Display
  static TextStyle get displayLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Large screen title using Averia Sans Libre.
  static TextStyle get averiaDisplayLarge => _withTitleFont(displayLarge);

  // Headlines
  static TextStyle get headlineMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// Section title using Averia Sans Libre.
  static TextStyle get averiaHeadlineMedium => _withTitleFont(headlineMedium);

  // Titles
  static TextStyle get titleLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );

  /// Card title using Averia Sans Libre.
  static TextStyle get averiaTitleLarge => _withTitleFont(titleLarge);

  static TextStyle get titleMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// Compact title using Averia Sans Libre.
  static TextStyle get averiaTitleMedium => _withTitleFont(titleMedium);

  // Body
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  // Labels
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );
}
