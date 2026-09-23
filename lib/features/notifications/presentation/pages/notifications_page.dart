/*
 * CareHub Plus — Notifications / NotificationsPage
 *
 * Tela de Notificações, aberta a partir de Configurações. Deixa a cuidadora
 * escolher quais alertas o aparelho dela recebe: SOS, rotina de tarefas, chat e
 * a forma de envio.
 *
 * A página é só composição — fornece o BLoC, trata carregamento, erro e vazio, e
 * delega o desenho para `NotificationsContent`.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../assistants/data/repositories/caregiver_avatar_repository.dart';
import '../../data/repositories/notification_preferences_repository.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notifications_content.dart';

/// Ponto de entrada da tela — fornece o BLoC e dispara o carregamento inicial.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsBloc(
        repository: NotificationPreferencesRepository(),
        avatarRepository: CaregiverAvatarRepository(),
      )..add(const NotificationsLoadEvent()),
      child: const _NotificationsView(),
    );
  }
}

/// View principal da tela de Notificações.
class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

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

  /// Falha ao salvar um interruptor não derruba a tela: o BLoC já devolveu o
  /// valor anterior, então basta avisar o que aconteceu.
  void _showSaveError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage &&
            current.status == NotificationsStatus.success,
        listener: (context, state) =>
            _showSaveError(context, state.errorMessage!),
        builder: (context, state) {
          return Column(
            children: [
              // O AppHeader já cuida da área da barra de status.
              AppHeader(
                photoUrl: state.caregiverPhotoUrl,
                onSettingsPressed: () => context.go(AppRoutes.settings),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: AppColors.splashGradient,
                  ),
                  child: _buildBody(context, state),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        // Notificações não é uma aba, então nenhum item fica destacado.
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    final preferences = state.preferences;

    switch (state.status) {
      case NotificationsStatus.initial:
      case NotificationsStatus.loading:
        return const AppLoading();

      case NotificationsStatus.failure:
        return AppErrorView(
          message:
              state.errorMessage ??
              'Erro ao carregar suas preferências de notificação.',
          onRetry: () => context.read<NotificationsBloc>().add(
            const NotificationsLoadEvent(),
          ),
        );

      case NotificationsStatus.success:
        if (preferences == null || preferences.values.isEmpty) {
          return const AppEmptyView(
            message: 'Nenhum alerta disponível para configurar agora.',
            icon: Icons.notifications_off_outlined,
          );
        }

        return NotificationsContent(
          preferences: preferences,
          onChanged: (preference, enabled) =>
              context.read<NotificationsBloc>().add(
                NotificationsTogglePreferenceEvent(
                  preference: preference,
                  enabled: enabled,
                ),
              ),
        );
    }
  }
}
