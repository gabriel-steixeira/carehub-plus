/*
 * CareHub Plus — Shared page frame
 *
 * Provides a consistent white background for the system header and footer while
 * keeping page content safely positioned between them on every device.
 *
 * Author: Vitoria Lana
 * Created on: 16/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Wraps a page body with white system bars and the device safe area.
class AppPageFrame extends StatelessWidget {
  const AppPageFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(child: child),
      ),
    );
  }
}
