import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
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
      backgroundColor: Colors.white, // Header area background
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
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
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

                    // Profiles Carousel
                    _buildProfilesCarousel(state.profiles),

                    const SizedBox(height: AppSpacing.xl),

                    // Add Profile Button
                    _buildAddProfileButton(),

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

  Widget _buildProfilesCarousel(List<CareRecipientModel> profiles) {
    if (profiles.isEmpty) {
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: profiles.map((profile) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _ProfileCard(profile: profile),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAddProfileButton() {
    return Builder(
      builder: (context) {
        return Column(
          children: [
            GestureDetector(
              onTap: () => AddProfileBottomSheet.show(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight, //.withValues(alpha: 0.7),
                  // -> só ficará com essa cor em caso de estar desativado,
                  // isso depois será pensado pelos planos dos aplicativos para controlarmos as funcionalidades e suas limitações
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
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final CareRecipientModel profile;

  @override
  Widget build(BuildContext context) {
    // Vovó Lúcia (or profile with notifications) has a beautiful purple border ring.
    final hasNotifications = profile.unreadNotificationsCount > 0;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.dashboard, extra: profile.id);
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Outer ring border
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasNotifications
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: profile.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(profile.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: AppColors.surfaceVariant,
                  ),
                  child: profile.photoUrl == null
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

              // Notification Badge (green for 0, red for > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: hasNotifications
                        ? AppColors.error
                        : AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${profile.unreadNotificationsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.name,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
