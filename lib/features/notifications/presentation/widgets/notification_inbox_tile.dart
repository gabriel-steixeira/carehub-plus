/*
 * CareHub Plus — Notificações / Card de um aviso
 *
 * Uma linha da caixa de notificações: ícone do assunto (SOS, tarefa, chat),
 * título, texto, há quanto tempo chegou e um ponto quando ainda não foi lida.
 * Só desenha o que recebe e avisa o toque.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/app_notification_entity.dart';

/// Card de um aviso da caixa de notificações.
class NotificationInboxTile extends StatelessWidget {
  const NotificationInboxTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.now,
  });

  final AppNotificationEntity notification;
  final VoidCallback onTap;

  /// Momento de referência para "há 5 min" (vem de fora para ser testável).
  final DateTime now;

  static const double _iconBoxSize = 40.0;
  static const double _unreadDotSize = 10.0;

  ({IconData icon, Color color}) get _visual => switch (notification.type) {
    AppNotificationType.sos => (
      icon: Icons.emergency_outlined,
      color: AppColors.error,
    ),
    AppNotificationType.task => (
      icon: Icons.checklist_rounded,
      color: AppColors.primaryDark,
    ),
    AppNotificationType.chat => (
      icon: Icons.chat_bubble_outline_rounded,
      color: AppColors.info,
    ),
    AppNotificationType.unknown => (
      icon: Icons.notifications_none_rounded,
      color: AppColors.textSecondary,
    ),
  };

  String get _elapsed {
    final diff = now.difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} d';
    final date = notification.createdAt;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final isUnread = notification.isUnread;

    return Semantics(
      label: isUnread ? 'Não lida' : null,
      child: AppCard(
        onTap: onTap,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _iconBoxSize,
              height: _iconBoxSize,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(visual.icon, size: 20, color: visual.color),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _elapsed,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Container(
                  width: _unreadDotSize,
                  height: _unreadDotSize,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
