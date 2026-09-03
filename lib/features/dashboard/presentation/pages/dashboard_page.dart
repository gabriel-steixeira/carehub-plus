/*
 * CareHub Plus — Dashboard / Dashboard Page
 *
 * Tela principal de resumo diário do cuidado. Exibe saudação contextual,
 * progresso do dia, próxima tarefa, alertas de atraso e sugestões da Cora.
 * O perfil ativo é fixo (escolhido na Home) — a troca ocorre pelo
 * ActiveProfileChip que navega de volta à seleção de perfil.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

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
import '../../data/repositories/dashboard_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/active_profile_chip.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/next_task_card.dart';
import '../widgets/suggestion_card.dart';

/// Entry point da tela — cria o BLoC e dispara o carregamento inicial.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.initialProfileId});

  final String? initialProfileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        repository: DashboardRepository(),
      )..add(DashboardLoadEvent(selectedProfileId: initialProfileId)),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        break; // já estamos no Dashboard
      case 1:
        final profileId =
            context.read<DashboardBloc>().state.selectedProfileId;
        context.push(AppRoutes.tasks, extra: profileId);
      case 2:
        context.push(AppRoutes.coraChat);
      case 3:
        final profileId =
            context.read<DashboardBloc>().state.selectedProfileId;
        context.push(AppRoutes.chat, extra: profileId);
      case 4:
        context.push(AppRoutes.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          // ── Loading inicial (sem dados anteriores em cache) ───────────────
          if (state.status == DashboardStatus.loading &&
              state.summary == null) {
            return const AppLoading();
          }

          // ── Falha sem nenhum dado para mostrar ────────────────────────────
          if (state.status == DashboardStatus.failure &&
              state.summary == null) {
            return AppErrorView(
              message: state.errorMessage ??
                  'Erro ao carregar o painel de controle.',
              onRetry: () => context.read<DashboardBloc>().add(
                    DashboardLoadEvent(
                      selectedProfileId: state.selectedProfileId,
                    ),
                  ),
            );
          }

          return Column(
            children: [
              AppHeader(photoUrl: state.caregiver?.photoUrl),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.splashGradient,
                  ),
                  child: SafeArea(
                    top: false,
                    child: _DashboardContent(state: state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) => AppBottomNavigation(
          currentIndex: 0,
          chatBadgeCount:
              context.read<DashboardBloc>().state.summary?.unreadChatsCount ??
              0,
          onTap: (index) => _onBottomNavTap(context, index),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo principal (scrollável)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final profile = state.selectedProfile;
    final caregiver = state.caregiver;
    final profileId = state.selectedProfileId;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: context.responsive(
          mobile: AppSpacing.md,
          tablet: AppSpacing.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chip de perfil ativo (affordance de troca) ───────────────────
          if (profile != null)
            ActiveProfileChip(
              profile: profile,
              onChangeTap: () => context.go(AppRoutes.home),
            ),

          const SizedBox(height: AppSpacing.md),

          // ── Cartão de progresso diário ────────────────────────────────────
          DailyProgressCard(
            caregiverName: caregiver?.name ?? 'Cuidadora',
            completedToday: summary?.completedTasksTodayCount ?? 0,
            totalToday: summary?.totalTasksTodayCount ?? 0,
            progress: summary?.dailyProgress ?? 0.0,
            allDone: summary?.allTasksDoneToday ?? false,
            onTap: () => context.push(AppRoutes.tasks, extra: profileId),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Linha: Próxima tarefa + Atrasadas ─────────────────────────────
          // NextTaskCard ocupa toda a largura quando não há atrasos;
          // divide com OverdueCard quando há tarefas atrasadas.
          if (summary != null && summary.overdueTasksCount > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: NextTaskCard(
                    nextTask: summary.nextTask,
                    onTap: () =>
                        context.push(AppRoutes.tasks, extra: profileId),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: OverdueCard(
                    overdueCount: summary.overdueTasksCount,
                    onTap: () =>
                        context.push(AppRoutes.tasks, extra: profileId),
                  ),
                ),
              ],
            ),
          ] else ...[
            NextTaskCard(
              nextTask: summary?.nextTask,
              onTap: () => context.push(AppRoutes.tasks, extra: profileId),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Chips de contexto (rede + chats) ─────────────────────────────
          Row(
            children: [
              _ContextChip(
                icon: Icons.groups_outlined,
                label: _networkLabel(summary?.supportNetworkCount ?? 0),
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.network),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ContextChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: _chatLabel(summary?.unreadChatsCount ?? 0),
                color: AppColors.tintPink,
                onTap: () => context.push(AppRoutes.chat, extra: profileId),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Sugestões da Cora ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sugestões da Cora IA',
                style: AppTypography.averiaDisplayLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: context.scaleFont(19),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.coraChat),
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

          if (summary != null && summary.suggestions.isNotEmpty) ...[
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
                    onActionTap: () => context.push(AppRoutes.coraChat),
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
    );
  }

  String _networkLabel(int count) {
    if (count == 0) return 'Rede de apoio vazia';
    if (count == 1) return '1 pessoa na rede';
    return '$count pessoas na rede';
  }

  String _chatLabel(int count) {
    if (count == 0) return 'Sem mensagens novas';
    if (count == 1) return '1 mensagem não lida';
    return '$count mensagens não lidas';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de contexto (rede / chats)
// ─────────────────────────────────────────────────────────────────────────────

/// Chip informativo de baixo relevo para dados secundários (rede e chats).
/// Menor destaque visual que os cartões de ação principal.
class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
