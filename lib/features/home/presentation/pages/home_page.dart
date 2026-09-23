/*
 * CareHub Plus — Home / Profile Selector Page
 *
 * Lets the Caregiver choose which Care Recipient to monitor.
 * Displays profiles in a 2-column adaptive grid where the last item is
 * centred when the total count is odd (2+1, 2+2+1, …).
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/models/care_recipient_model.dart';
import '../../data/repositories/home_repository.dart';
import '../bloc/home_bloc.dart';
import '../widgets/add_profile_bottom_sheet.dart';

/// Home Page — lets the Caregiver choose which Care Recipient to monitor.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeBloc(repository: HomeRepository())..add(const HomeLoadEvent()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading) {
            return const Center(child: AppLoading());
          }
          if (state.status == HomeStatus.failure) {
            return AppErrorView(
              message:
                  state.errorMessage ??
                  'Ocorreu um erro ao carregar os perfis.',
              onRetry: () {
                context.read<HomeBloc>().add(const HomeLoadEvent());
              },
            );
          }
          if (state.status == HomeStatus.success) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    return Column(
      children: [
        // 1. Header (White background)
        AppHeader(photoUrl: state.caregiver?.photoUrl),

        // 2. Body (Gradient background)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxxl,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // Title
                    Text(
                      'Quem vamos cuidar\nagora?',
                      textAlign: TextAlign.center,
                      style: AppTypography.averiaTitleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: context.scaleFont(32),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subtitle
                    Text(
                      'Selecione o perfil para começar o\nacompanhamento.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.scaleFont(16),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Profiles Grid
                    _ProfilesGrid(profiles: state.profiles),

                    const SizedBox(height: AppSpacing.xl),

                    // Add Profile Button
                    _AddProfileButton(),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profiles Grid
// ---------------------------------------------------------------------------

/// Renders profiles 2-per-row. When the total count is odd, the last item
/// occupies a full row centred — giving the 2 / 2+1 / 2+2 / 2+2+1 rhythm
/// requested.
class _ProfilesGrid extends StatelessWidget {
  const _ProfilesGrid({required this.profiles});

  final List<CareRecipientModel> profiles;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return _EmptyState();
    }

    final bool isOdd = profiles.length % 2 != 0;

    // Build rows manually so the last centred item is always properly sized.
    final List<Widget> rows = [];
    final int pairCount = profiles.length ~/ 2;

    for (int i = 0; i < pairCount; i++) {
      rows.add(
        _ProfileRow(
          left: profiles[i * 2],
          right: profiles[i * 2 + 1],
        ),
      );
      rows.add(const SizedBox(height: AppSpacing.xl));
    }

    if (isOdd) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProfileCard(profile: profiles.last),
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.left, required this.right});

  final CareRecipientModel left;
  final CareRecipientModel right;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ProfileCard(profile: left),
        _ProfileCard(profile: right),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nenhum perfil cadastrado',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cadastre o primeiro assistido ou pet abaixo.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add Profile Button
// ---------------------------------------------------------------------------

class _AddProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => AddProfileBottomSheet.show(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Adicionar Perfil',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Card
// ---------------------------------------------------------------------------

/// Card for a single Care Recipient.
///
/// Layout (top → bottom):
///   • Avatar with optional notification badge (top-right, only when > 0)
///   • Name
///   • Delete button — discrete trash icon below the name, far from the avatar
///     so the user never accidentally deletes while trying to tap the photo.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final CareRecipientModel profile;

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remover perfil?',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Tem certeza que deseja remover o perfil de ${profile.name}? '
          'Esta ação não pode ser desfeita.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HomeBloc>().add(
                    HomeDeleteProfileEvent(profileId: profile.id),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Perfil de ${profile.name} removido.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              );
            },
            child: Text(
              'Remover',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPending = profile.unreadNotificationsCount > 0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.dashboard, extra: profile.id),
      child: SizedBox(
        width: 130,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Outer ring — visible only when there are pending items
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasPending
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: _buildProfileImage(),
                      color: AppColors.surfaceVariant,
                    ),
                    child: !profile.hasPhoto
                        ? Icon(
                            profile.type == 'pet'
                                ? Icons.pets
                                : Icons.person_outline,
                            size: 40,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),

                // Pending badge — only shown when count > 0
                if (hasPending)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: profile.unreadNotificationsCount > 9
                            ? AppColors.error
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        profile.unreadNotificationsCount > 99
                            ? '99+'
                            : '${profile.unreadNotificationsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Name ─────────────────────────────────────────────────────────
            Text(
              profile.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // ── Delete action ─────────────────────────────────────────────
            // Kept below the name so it is clearly separated from the avatar
            // tap target and is less likely to be triggered accidentally.
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Remover',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the profile image from base64 or URL, whichever is available.
  DecorationImage? _buildProfileImage() {
    if (profile.photoBase64 != null) {
      final raw = profile.photoBase64!;
      final base64Str = raw.contains(',') ? raw.split(',').last : raw;
      return DecorationImage(
        image: MemoryImage(base64Decode(base64Str)),
        fit: BoxFit.cover,
      );
    }
    if (profile.photoUrl != null) {
      return DecorationImage(
        image: NetworkImage(profile.photoUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
