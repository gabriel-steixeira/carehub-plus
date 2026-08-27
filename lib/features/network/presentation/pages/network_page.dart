/*
 * CareHub Plus — Network / NetworkPage
 *
 * Tela de gerenciamento da Rede de Apoio. Permite visualizar, adicionar e
 * remover membros que recebem alertas e acessam as informações do cuidado.
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
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/network_repository.dart';
import '../bloc/network_bloc.dart';
import '../widgets/add_member_bottom_sheet.dart';
import '../widgets/member_card.dart';

/// Ponto de entrada da tela — fornece o BLoC e dispara o carregamento inicial.
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key, this.careRecipientId});

  final String? careRecipientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NetworkBloc(
        repository: NetworkRepository(),
        careRecipientId: careRecipientId,
      )..add(const NetworkLoadEvent()),
      child: _NetworkView(careRecipientId: careRecipientId),
    );
  }
}

/// View principal da tela de Rede de Apoio.
class _NetworkView extends StatelessWidget {
  const _NetworkView({this.careRecipientId});

  final String? careRecipientId;

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
      body: BlocBuilder<NetworkBloc, NetworkState>(
        builder: (context, state) {
          if (state.status == NetworkStatus.loading && state.members.isEmpty) {
            return const AppLoading();
          }

          if (state.status == NetworkStatus.failure && state.members.isEmpty) {
            return AppErrorView(
              message:
                  state.errorMessage ?? 'Erro ao carregar a rede de apoio.',
              onRetry: () =>
                  context.read<NetworkBloc>().add(const NetworkLoadEvent()),
            );
          }

          return Column(
            children: [
              // ── Header padrão do app (lida com status bar internamente) ──
              const AppHeader(showSettings: true),

              // ── Conteúdo scrollável com gradiente ─────────────────────
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Título e subtítulo ──────────────────────
                          Text(
                            'Redes de Apoio',
                            style: AppTypography.averiaHeadlineMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Gerencie quem recebe alertas e acessa suas informações.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ── Botão "Adicionar Novo Membro" ───────────
                          _AddMemberButton(
                            onTap: () => AddMemberBottomSheet.show(
                              context,
                              careRecipientId: careRecipientId,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ── Lista de membros ────────────────────────
                          ...state.members.map(
                            (member) => MemberCard(
                              member: member,
                              onEdit: () => AddMemberBottomSheet.show(
                                context,
                                member: member,
                                careRecipientId: careRecipientId,
                              ),
                              onRemove: () => context.read<NetworkBloc>().add(
                                NetworkRemoveMemberEvent(memberId: member.id),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // ── Banner informativo ──────────────────────
                          const _ImportantBanner(),
                          const SizedBox(height: AppSpacing.md),
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
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets internos
// ─────────────────────────────────────────────────────────────────────────────

/// Botão primário cheio para adicionar um novo membro.
class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        icon: const Icon(
          Icons.person_add_alt_1_outlined,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Adicionar Novo Membro',
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Painel lilás com informação sobre notificações SOS.
class _ImportantBanner extends StatelessWidget {
  const _ImportantBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone de informação
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importante',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Contatos principais são notificados por SMS e chamadas de '
                  'voz automáticas em caso de acionamento do botão SOS.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
