/*
 * CareHub Plus — SOS / Etapa 1: montar o pedido
 *
 * Primeira etapa da tela de SOS: filtrar o perfil cuidado, escolher a tarefa em
 * que a ajuda é necessária, revisar quem da rede de apoio será avisado e
 * disparar o alerta. Só compõe widgets e reporta intenções ao BLoC.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../tasks/presentation/models/tasks_navigation_args.dart';
import '../bloc/sos_bloc.dart';
import 'sos_button.dart';
import 'sos_network_picker.dart';
import 'sos_task_picker.dart';

/// Etapa de montagem do pedido de ajuda.
class SosComposeView extends StatelessWidget {
  const SosComposeView({super.key, required this.state});

  final SosState state;

  Future<void> _selectTaskFromTasks(BuildContext context, SosBloc bloc) async {
    final taskId = await context.push<String>(
      AppRoutes.tasks,
      extra: TasksNavigationArgs(
        careRecipientId: state.selectedProfileId,
        isSosSelectionMode: true,
      ),
    );

    if (!context.mounted || taskId == null) return;
    bloc.add(SosTaskSelectedEvent(taskId: taskId));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SosBloc>();

    Future<void> openNetwork() async {
      await context.push(AppRoutes.network, extra: state.selectedProfileId);
      if (!context.mounted) return;
      bloc.add(SosLoadEvent(careRecipientId: state.selectedProfileId));
    }

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.sectionSpacing),
          Text(
            'Pedir ajuda',
            style: AppTypography.averiaDisplayLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.scaleFont(30),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Avise sua rede de apoio sobre uma tarefa que você não consegue '
            'fazer agora.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          const _SectionTitle(
            icon: Icons.checklist_rounded,
            label: 'Qual tarefa precisa de ajuda?',
          ),
          const SizedBox(height: AppSpacing.smMd),
          SosTaskPicker(
            tasks: state.openTasks,
            selectedTaskId: state.selectedTaskId,
            onChangeTask: () => _selectTaskFromTasks(context, bloc),
          ),
          SizedBox(height: context.sectionSpacing),
          Text(
            'Rede de Apoio',
            style: AppTypography.averiaHeadlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
          SosNetworkPicker(
            members: state.members,
            notifiedMemberIds: state.notifiedMemberIds,
            onMemberToggled: (memberId) =>
                bloc.add(SosMemberToggledEvent(memberId: memberId)),
            onOpenNetwork: openNetwork,
          ),
          SizedBox(height: context.sectionSpacing),
          Center(
            child: Column(
              children: [
                SosButton(
                  onPressed: state.canTriggerAlert
                      ? () => bloc.add(const SosAlertRequestedEvent())
                      : null,
                ),
                const SizedBox(height: AppSpacing.smMd),
                Text(
                  'Pressione e segure',
                  textAlign: TextAlign.center,
                  style: AppTypography.averiaDisplayLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: context.scaleFont(24),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Mantenha pressionado por 3\n'
                  'segundos para alertar sua rede de\n'
                  'apoio.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          const _AverageResponseTimeCard(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Cabeçalho de seção do formulário.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.averiaDisplayLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.scaleFont(18),
            ),
          ),
        ),
      ],
    );
  }
}

/// Aviso visual com o tempo médio de resposta apresentado no protótipo.
class _AverageResponseTimeCard extends StatelessWidget {
  const _AverageResponseTimeCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: double.infinity,
      child: Row(
        children: [
          Container(
            width: AppSpacing.xxxl,
            height: AppSpacing.xxxl,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.av_timer_rounded,
              size: AppSpacing.xl,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Tempo médio de resposta da sua rede: '),
                  TextSpan(
                    text: '4 minutos',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
