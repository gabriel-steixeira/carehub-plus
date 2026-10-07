/*
 * CareHub Plus — Componente / Sino de notificações
 *
 * Ícone de sino com a contagem de avisos não lidos, usado pelo `AppHeader`.
 * Lê o `NotificationInboxBloc` da raiz do app, então atualiza em tempo real
 * em qualquer tela. Fica invisível quando ninguém está logado (telas de
 * login e cadastro) ou quando não há BLoC acima dele (testes isolados).
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/notifications/presentation/bloc/notification_inbox_bloc.dart';

/// Sino com contador de notificações não lidas.
class AppNotificationBell extends StatelessWidget {
  const AppNotificationBell({super.key});

  /// Acima disso, o selo mostra "9+" para não estourar o círculo.
  static const int _maxBadgeCount = 9;
  static const double _badgeMinSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final NotificationInboxBloc bloc;
    try {
      bloc = BlocProvider.of<NotificationInboxBloc>(context);
    } catch (_) {
      // Sem o BLoC na árvore (ex.: teste de um widget isolado): sem sino.
      return const SizedBox.shrink();
    }

    return BlocBuilder<NotificationInboxBloc, NotificationInboxState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          previous.isSignedIn != current.isSignedIn ||
          previous.unreadCount != current.unreadCount,
      builder: (context, state) {
        if (!state.isSignedIn) return const SizedBox.shrink();

        final count = state.unreadCount;
        final label = count == 0
            ? 'Notificações'
            : 'Notificações, $count não lida${count == 1 ? '' : 's'}';

        return IconButton(
          tooltip: label,
          onPressed: () => context.push(AppRoutes.notificationInbox),
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: AppColors.error,
            textColor: AppColors.textInverse,
            textStyle: AppTypography.labelSmall,
            largeSize: _badgeMinSize,
            label: Text(count > _maxBadgeCount ? '$_maxBadgeCount+' : '$count'),
            child: Icon(
              count > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
              size: 24,
              semanticLabel: label,
            ),
          ),
        );
      },
    );
  }
}
