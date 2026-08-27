/*
 * CareHub Plus — Apresentação / Seção de Preferências de Notificação
 *
 * Rótulo em caixa alta (ex.: "ALERTAS CRÍTICOS") seguido do cartão branco com as
 * preferências daquela seção, separadas por divisórias. Quais preferências
 * entram vem do domínio, não de uma lista repetida na página.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import 'notification_preference_tile.dart';

/// Raio do cartão da seção, compartilhado entre o [AppCard] e o recorte do
/// efeito de toque para os dois nunca saírem de sincronia.
const double _cardRadius = AppSpacing.radiusMd;

/// Um bloco temático da tela de Notificações.
class NotificationPreferenceSection extends StatelessWidget {
  const NotificationPreferenceSection({
    super.key,
    required this.section,
    required this.preferences,
    required this.onChanged,
  });

  final NotificationSection section;

  /// Estado atual de todas as preferências do cuidador.
  final NotificationPreferencesEntity preferences;

  /// Disparado quando um interruptor da seção muda.
  final void Function(NotificationPreference preference, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = NotificationPreference.ofSection(section);
    final label = section.label.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          borderRadius: _cardRadius,
          // Sem o recorte, o efeito de toque da primeira e da última linha
          // vazaria por cima dos cantos arredondados do cartão.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  NotificationPreferenceTile(
                    preference: items[i],
                    isEnabled: preferences.isEnabled(items[i]),
                    onChanged: (enabled) => onChanged(items[i], enabled),
                  ),
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: AppColors.divider,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
