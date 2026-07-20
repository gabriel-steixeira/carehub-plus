import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/settings_repository.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/setting_toggle_tile.dart';

/// Caregiver Profile & Settings Page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(
        repository: SettingsRepository(),
      )..add(const SettingsLoadEvent()),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          'Configurações da Conta',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state.status == SettingsStatus.loading) {
              return const AppLoading();
            }

            final notifs = state.notifications;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caregiver Profile Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maria Oliveira',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'maria@carehub.com',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusXs),
                                ),
                                child: Text(
                                  'Cuidador Responsável',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primaryDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Notifications Section
                  Text(
                    'Notificações e Alertas',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  SettingToggleTile(
                    title: 'Notificações Push',
                    subtitle: 'Alertas em tempo real no dispositivo',
                    icon: Icons.notifications_active_outlined,
                    value: notifs['pushEnabled'] ?? true,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            SettingsToggleNotificationEvent(
                              key: 'pushEnabled',
                              value: val,
                            ),
                          );
                    },
                  ),
                  SettingToggleTile(
                    title: 'Lembretes de Medicação',
                    subtitle: 'Alertar horários de remédios dos assistidos',
                    icon: Icons.medication_liquid_outlined,
                    value: notifs['medicationReminders'] ?? true,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            SettingsToggleNotificationEvent(
                              key: 'medicationReminders',
                              value: val,
                            ),
                          );
                    },
                  ),
                  SettingToggleTile(
                    title: 'Alertas Proativos da Cora IA',
                    subtitle: 'Sugestões preditivas e dicas de saúde',
                    icon: Icons.auto_awesome_outlined,
                    value: notifs['coraProactiveAlerts'] ?? true,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            SettingsToggleNotificationEvent(
                              key: 'coraProactiveAlerts',
                              value: val,
                            ),
                          );
                    },
                  ),
                  SettingToggleTile(
                    title: 'Chat da Rede de Apoio',
                    subtitle: 'Notificar novas mensagens da equipe de cuidado',
                    icon: Icons.chat_bubble_outline_rounded,
                    value: notifs['networkChatNotifications'] ?? true,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            SettingsToggleNotificationEvent(
                              key: 'networkChatNotifications',
                              value: val,
                            ),
                          );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Actions Section
                  Text(
                    'Conta e Segurança',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    leading:
                        const Icon(Icons.people_outline, color: AppColors.primary),
                    title: Text(
                      'Alternar Perfil Cuidado',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Logout Button
                  AppButton(
                    label: 'Sair da Conta',
                    variant: AppButtonVariant.destructive,
                    icon: Icons.logout,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
