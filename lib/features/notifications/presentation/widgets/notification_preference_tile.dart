/*
 * CareHub Plus — Apresentação / Linha de Preferência de Notificação
 *
 * Uma linha da tela de Notificações: nome do alerta, explicação curta e o
 * interruptor. Todo o texto vem do enum de domínio, então esta classe não sabe
 * quais alertas existem — acrescentar um novo não exige mudar nada aqui.
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
import '../../domain/entities/notification_preference.dart';

/// Linha com interruptor de uma preferência de notificação.
class NotificationPreferenceTile extends StatelessWidget {
  const NotificationPreferenceTile({
    super.key,
    required this.preference,
    required this.isEnabled,
    required this.onChanged,
  });

  final NotificationPreference preference;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final description = preference.description;

    // MergeSemantics junta título, explicação e interruptor em um único item
    // para o leitor de tela, do mesmo jeito que o SwitchListTile faz. Sem isso
    // a pessoa ouviria "ligado" solto, sem saber a que se refere.
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!isEnabled),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preference.label,
                      style: AppTypography.averiaTitleMedium.copyWith(
                        // Desligado, o título perde força para a lista mostrar
                        // de longe o que está ativo.
                        color: isEnabled
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch(
                value: isEnabled,
                onChanged: onChanged,
                activeThumbColor: AppColors.background,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.background,
                inactiveTrackColor: AppColors.divider,
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
