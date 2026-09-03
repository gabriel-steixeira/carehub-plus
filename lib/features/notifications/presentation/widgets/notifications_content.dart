/*
 * CareHub Plus — Apresentação / Conteúdo da Tela de Notificações
 *
 * Título, subtítulo e as seções de preferências. Fica separado da página para a
 * página seguir sendo só composição (BLoC + estados de carregamento, erro e
 * vazio), como manda a arquitetura.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import 'notification_preference_section.dart';

/// Corpo rolável da tela de Notificações.
class NotificationsContent extends StatelessWidget {
  const NotificationsContent({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final NotificationPreferencesEntity preferences;
  final void Function(NotificationPreference preference, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBody(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePaddingHorizontal,
        vertical: context.sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notificações',
            style: AppTypography.averiaHeadlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escolha quais alertas você deseja receber no seu dispositivo.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          for (final section in NotificationSection.values) ...[
            SizedBox(height: context.scaleSpacing(AppSpacing.md)),
            NotificationPreferenceSection(
              section: section,
              preferences: preferences,
              onChanged: onChanged,
            ),
          ],
          SizedBox(height: context.scaleSpacing(AppSpacing.md)),
        ],
      ),
    );
  }
}
