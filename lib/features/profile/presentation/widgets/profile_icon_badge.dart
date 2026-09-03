/*
 * CareHub Plus — Perfil / Selo de Ícone
 *
 * Quadrado lilás claro com o ícone da seção, usado nos cartões de Privacidade e
 * de Plano. Existe para os dois cartões terem exatamente o mesmo selo, sem
 * repetir decoração em cada um.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Selo quadrado com ícone, no tom lilás claro do design system.
class ProfileIconBadge extends StatelessWidget {
  const ProfileIconBadge({super.key, required this.icon});

  final IconData icon;

  /// 40px — `xxl` menos `sm`, mantendo o grid de 4px.
  static const double _size = AppSpacing.xxl - AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: AppColors.primary, size: AppSpacing.lg),
    );
  }
}
