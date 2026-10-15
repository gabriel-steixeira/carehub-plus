import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/settings_repository.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/delete_account_reauth_sheet.dart';
import '../widgets/delete_account_warning_sheet.dart';

/// Caregiver Profile & Settings Page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsBloc(repository: SettingsRepository())
            ..add(const SettingsLoadEvent()),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.push(AppRoutes.tasks);
        break;
      case 2:
        context.push(AppRoutes.coraChat);
        break;
      case 3:
        context.push(AppRoutes.chat);
        break;
      case 4:
        context.push(AppRoutes.sos);
        break;
    }
  }

  /// Reage ao fluxo de exclusão de conta (resolver -> aviso -> reautenticar).
  Future<void> _onDeletionStateChanged(
    BuildContext context,
    SettingsState state,
  ) async {
    switch (state.deletionStatus) {
      case SettingsDeletionStatus.ready:
        final preview = state.deletionPreview;
        if (preview == null) return;

        final bloc = context.read<SettingsBloc>();
        final wantsToContinue = await DeleteAccountWarningSheet.show(
          context,
          preview: preview,
        );
        if (!context.mounted || !wantsToContinue) return;

        final reauthenticated = await DeleteAccountReauthSheet.show(context);
        if (!context.mounted || !reauthenticated) return;

        bloc.add(const SettingsDeleteAccountEvent());
        break;

      case SettingsDeletionStatus.deleted:
        await AuthService().signOut();
        if (!context.mounted) return;
        context.go(AppRoutes.login);
        break;

      case SettingsDeletionStatus.failure:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                state.deletionError ??
                    'Não foi possível excluir a conta agora. Tente novamente.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        break;

      case SettingsDeletionStatus.idle:
      case SettingsDeletionStatus.resolving:
      case SettingsDeletionStatus.deleting:
        break;
    }
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$label estará disponível em breve.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Header area background
      body: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) =>
            previous.deletionStatus != current.deletionStatus,
        listener: _onDeletionStateChanged,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
          if (state.status == SettingsStatus.loading) {
            return const AppLoading();
          }

          if (state.status == SettingsStatus.failure &&
              state.caregiver == null) {
            return AppErrorView(
              message:
                  state.errorMessage ??
                  'Erro ao carregar as configurações da conta.',
              onRetry: () {
                context.read<SettingsBloc>().add(const SettingsLoadEvent());
              },
            );
          }

          final caregiver = state.caregiver;

          return Column(
            children: [
              // Top App Bar Header (same as Home / Dashboard).
              AppHeader(
                photoUrl: caregiver?.photoUrl,
                photoBase64: caregiver?.photoBase64,
              ),

              // Main body with the app gradient background.
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.splashGradient,
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileCard(
                            name: caregiver?.name ?? '',
                            secondary: caregiver?.email ?? '',
                            photoUrl: caregiver?.photoUrl,
                            photoBase64: caregiver?.photoBase64,
                            onEdit: () => context.push(AppRoutes.editProfile),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Grouped options list.
                          _SettingsMenuCard(
                            items: [
                              _SettingsMenuItem(
                                icon: Icons.groups_outlined,
                                label: 'Rede de Apoio',
                                onTap: () => context.push(AppRoutes.network),
                              ),
                              _SettingsMenuItem(
                                icon: Icons.notifications_outlined,
                                label: 'Notificações',
                                onTap: () =>
                                    context.push(AppRoutes.notifications),
                              ),
                              _SettingsMenuItem(
                                icon: Icons.headset_mic_outlined,
                                label: 'Fale conosco\n(Concierge Toke)',
                                onTap: () => context.push(AppRoutes.tokeChat),
                              ),
                              _SettingsMenuItem(
                                icon: Icons.settings_outlined,
                                label: 'Preferências',
                                onTap: () =>
                                    _showComingSoon(context, 'Preferências'),
                              ),
                              _SettingsMenuItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Planos',
                                onTap: () =>
                                    context.push(AppRoutes.subscriptions),
                              ),
                              _SettingsMenuItem(
                                icon: Icons.info_outline_rounded,
                                label: 'Sobre',
                                onTap: () => context.push(AppRoutes.about),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Logout action.
                          Center(
                            child: TextButton.icon(
                              onPressed: () => context.go(AppRoutes.login),
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              label: Text(
                                'Sair da Conta',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          // Delete account action (destructive).
                          Center(
                            child: TextButton.icon(
                              onPressed:
                                  state.deletionStatus ==
                                          SettingsDeletionStatus.resolving ||
                                      state.deletionStatus ==
                                          SettingsDeletionStatus.deleting
                                  ? null
                                  : () => context.read<SettingsBloc>().add(
                                      const SettingsResolveDeletionEvent(),
                                    ),
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              label: Text(
                                'Excluir conta',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        // Settings is opened from the header gear, so no tab is highlighted.
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}

/// Caregiver profile card: avatar, name, secondary info and an edit action.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.secondary,
    required this.photoUrl,
    required this.photoBase64,
    required this.onEdit,
  });

  final String name;
  final String secondary;
  final String? photoUrl;
  final String? photoBase64;
  final VoidCallback onEdit;

  static Uint8List? _decodeBase64(String? value) {
    if (value == null || value.isEmpty) return null;

    final separatorIndex = value.indexOf(',');
    final encoded = separatorIndex >= 0
        ? value.substring(separatorIndex + 1)
        : value;

    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoBytes = _decodeBase64(photoBase64);
    final normalizedPhotoUrl = photoUrl == null || photoUrl!.isEmpty
        ? null
        : photoUrl;
    final hasPhoto = photoBytes != null || normalizedPhotoUrl != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
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
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            backgroundImage: photoBytes != null
                ? MemoryImage(photoBytes)
                : normalizedPhotoUrl == null
                ? null
                : NetworkImage(normalizedPhotoUrl),
            child: hasPhoto
                ? null
                : const Icon(Icons.person, size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _EditPillButton(onTap: onEdit),
        ],
      ),
    );
  }
}

/// Purple pill button used to edit the caregiver profile.
class _EditPillButton extends StatelessWidget {
  const _EditPillButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'Editar',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card grouping the settings options with dividers.
class _SettingsMenuCard extends StatelessWidget {
  const _SettingsMenuCard({required this.items});

  final List<_SettingsMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
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
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
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
    );
  }
}

/// Single tappable row inside [_SettingsMenuCard].
class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: AppColors.textInverse, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
