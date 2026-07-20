import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/network_repository.dart';
import '../bloc/network_bloc.dart';
import '../widgets/add_member_bottom_sheet.dart';
import '../widgets/member_card.dart';

/// Support Network Management Page.
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NetworkBloc(
        repository: NetworkRepository(),
      )..add(const NetworkLoadEvent()),
      child: const NetworkView(),
    );
  }
}

class NetworkView extends StatelessWidget {
  const NetworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          'Rede de Apoio',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.primary),
            onPressed: () => AddMemberBottomSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<NetworkBloc, NetworkState>(
          builder: (context, state) {
            if (state.status == NetworkStatus.loading &&
                state.members.isEmpty) {
              return const AppLoading();
            }

            if (state.status == NetworkStatus.failure &&
                state.members.isEmpty) {
              return AppErrorView(
                message: state.errorMessage ??
                    'Erro ao carregar a rede de apoio.',
                onRetry: () {
                  context.read<NetworkBloc>().add(const NetworkLoadEvent());
                },
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header Info
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Equipe de Cuidado Compartilhado',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${state.members.length} membros ativos colaborando no acompanhamento.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Membros Cadastrados',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  ...state.members.map((member) {
                    return MemberCard(
                      member: member,
                      onRemove: () {
                        context.read<NetworkBloc>().add(
                              NetworkRemoveMemberEvent(memberId: member.id),
                            );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddMemberBottomSheet.show(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Convidar Membro',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
