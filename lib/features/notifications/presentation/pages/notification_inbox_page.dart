/*
 * CareHub Plus — Notificações / Caixa de notificações
 *
 * Lista os avisos da pessoa logada (acionada num SOS, incluída numa tarefa ou
 * num chat novo), aberta pelo sino do `AppHeader`. Lê o
 * `NotificationInboxBloc` da raiz do app — a lista atualiza sozinha quando o
 * backend cria um aviso. Trata carregamento, erro e caixa vazia.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../bloc/notification_inbox_bloc.dart';
import '../widgets/notification_inbox_tile.dart';

/// Tela com a lista de notificações recebidas.
class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.tasks);
      case 2:
        context.go(AppRoutes.coraChat);
      case 3:
        context.go(AppRoutes.chat);
      case 4:
        context.go(AppRoutes.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            AppHeader(
              // Já estamos na caixa: o sino aqui só repetiria a tela.
              showNotifications: false,
              leading: AppBackButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child:
                    BlocConsumer<NotificationInboxBloc, NotificationInboxState>(
                      listenWhen: (previous, current) =>
                          current.status == NotificationInboxStatus.ready &&
                          current.errorMessage != null &&
                          current.errorMessage != previous.errorMessage,
                      listener: (context, state) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.errorMessage!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textInverse,
                                ),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          ),
                      builder: (context, state) => _buildBody(context, state),
                    ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationInboxState state) {
    final bloc = context.read<NotificationInboxBloc>();

    switch (state.status) {
      case NotificationInboxStatus.initial:
      case NotificationInboxStatus.loading:
        return const AppLoading();

      case NotificationInboxStatus.failure:
        return AppErrorView(
          message:
              state.errorMessage ??
              'Não foi possível carregar suas notificações.',
          onRetry: () => bloc.add(const NotificationInboxStartedEvent()),
        );

      case NotificationInboxStatus.ready:
        if (state.items.isEmpty) {
          return const AppEmptyView(
            message:
                'Nenhuma notificação por aqui. Você será avisada quando for '
                'acionada num SOS ou incluída numa tarefa ou chat.',
            icon: Icons.notifications_none_rounded,
          );
        }

        final now = DateTime.now();
        return AppResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notificações',
                      style: AppTypography.averiaHeadlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () =>
                          bloc.add(const NotificationInboxMarkAllAsReadEvent()),
                      child: Text(
                        'Marcar todas como lidas',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in state.items)
                NotificationInboxTile(
                  notification: item,
                  now: now,
                  onTap: () => bloc.add(
                    NotificationInboxMarkAsReadEvent(notificationId: item.id),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
    }
  }
}
