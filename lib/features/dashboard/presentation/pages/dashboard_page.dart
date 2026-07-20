import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../home/data/models/care_recipient_model.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/kpi_card.dart';
import '../widgets/profile_chip_filter.dart';
import '../widgets/suggestion_card.dart';

/// Dashboard Page — Main overview dashboard after profile selection.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.initialProfileId});

  final String? initialProfileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        repository: DashboardRepository(),
      )..add(DashboardLoadEvent(selectedProfileId: initialProfileId)),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on Dashboard / Home
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state.status == DashboardStatus.loading &&
                state.summary == null) {
              return const AppLoading();
            }

            if (state.status == DashboardStatus.failure &&
                state.summary == null) {
              return AppErrorView(
                message: state.errorMessage ??
                    'Erro ao carregar o painel de controle.',
                onRetry: () {
                  context.read<DashboardBloc>().add(
                        DashboardLoadEvent(
                          selectedProfileId: state.selectedProfileId,
                        ),
                      );
                },
              );
            }

            final activeProfile = state.selectedProfile;
            final summary = state.summary;

            return Column(
              children: [
                // Top App Bar Header
                _buildHeader(context, state),
                const SizedBox(height: AppSpacing.sm),

                // Profile Filter Chips
                ProfileChipFilter(
                  profiles: state.profiles,
                  selectedProfileId: state.selectedProfileId,
                  onProfileSelected: (profileId) {
                    context
                        .read<DashboardBloc>()
                        .add(DashboardSelectProfileEvent(profileId: profileId));
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // Main Dashboard Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        _buildSearchBar(context),
                        const SizedBox(height: AppSpacing.lg),

                        // Active Profile Banner Info
                        if (activeProfile != null) ...[
                          _buildProfileBanner(activeProfile),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // KPIs Grid (2x2)
                        Text(
                          'Resumo Diário',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildKpiGrid(context, summary),
                        const SizedBox(height: AppSpacing.xl),

                        // Cora Suggestions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sugestões da Cora IA',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.coraChat),
                              child: Text(
                                'Falar com Cora',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        if (summary != null &&
                            summary.suggestions.isNotEmpty) ...[
                          SizedBox(
                            height: 175,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: summary.suggestions.length,
                              itemBuilder: (context, index) {
                                final sug = summary.suggestions[index];
                                return SuggestionCard(
                                  suggestion: sug,
                                  onActionTap: () {
                                    context.push(AppRoutes.coraChat);
                                  },
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              'Nenhuma sugestão no momento. Tudo tranquilo por aqui!',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: state.caregiver?.photoUrl != null
                    ? NetworkImage(state.caregiver!.photoUrl!)
                    : null,
                child: state.caregiver?.photoUrl == null
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${state.caregiver?.name.split(' ').first ?? 'Cuidador'}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'CareHub Plus',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
                tooltip: 'Cora Assistant',
                onPressed: () => context.push(AppRoutes.coraChat),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textSecondary),
                tooltip: 'Configurações',
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (query) {
          context
              .read<DashboardBloc>()
              .add(DashboardSearchQueryChangedEvent(query: query));
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar tarefas, lembretes ou cuidados...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          icon: const Icon(Icons.search, color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(CareRecipientModel profile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? Icon(
                    profile.type == 'pet' ? Icons.pets : Icons.person,
                    color: AppColors.primary,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitorando ${profile.name}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.type == 'pet'
                      ? 'Perfil Pet registrado'
                      : 'Perfil de Cuidado Ativo',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, DashboardSummaryModel? summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        KpiCard(
          title: 'Perfis Monitorados',
          value: '${summary?.monitoredProfilesCount ?? 0}',
          icon: Icons.people_outline,
          color: AppColors.primary,
          onTap: () => context.go(AppRoutes.home),
        ),
        KpiCard(
          title: 'Tarefas Pendentes',
          value: '${summary?.pendingTasksCount ?? 0}',
          icon: Icons.assignment_outlined,
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.tasks),
        ),
        KpiCard(
          title: 'Rede de Apoio',
          value: '${summary?.supportNetworkCount ?? 0}',
          icon: Icons.groups_outlined,
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.network),
        ),
        KpiCard(
          title: 'Chats Pendentes',
          value: '${summary?.unreadChatsCount ?? 0}',
          icon: Icons.chat_bubble_outline,
          color: AppColors.success,
          onTap: () => context.push(AppRoutes.chat),
        ),
      ],
    );
  }
}
