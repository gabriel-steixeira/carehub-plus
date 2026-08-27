/*
 * CareHub Plus — SOS / Etapa 2: alerta enviado
 *
 * Segunda etapa do fluxo: o pedido foi enviado e a tela mostra a tarefa, quem
 * foi avisado e a contagem regressiva até a resposta da rede de apoio. É a
 * janela em que a cuidadora ainda pode cancelar — o cancelamento passa por uma
 * confirmação, e o tempo fica pausado enquanto ela decide.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../../shared/widgets/app_tinted_card.dart';
import '../bloc/sos_bloc.dart';
import 'sos_cancel_confirmation_sheet.dart';
import 'sos_member_tile.dart';
import 'sos_selectable_card.dart';

/// Etapa do alerta enviado, com contagem regressiva e cancelamento.
class SosAlertingView extends StatelessWidget {
  const SosAlertingView({super.key, required this.state});

  final SosState state;

  Future<void> _confirmCancellation(BuildContext context) async {
    final bloc = context.read<SosBloc>();
    final messenger = ScaffoldMessenger.of(context);

    bloc.add(const SosCountdownPausedEvent());
    final isConfirmed = await SosCancelConfirmationSheet.show(context);

    if (!isConfirmed) {
      bloc.add(const SosCountdownResumedEvent());
      return;
    }

    bloc.add(const SosAlertCancelledEvent());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Pedido de ajuda cancelado.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        backgroundColor: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskTitle = state.selectedTask?.title ?? 'Tarefa de cuidado';

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: context.sectionSpacing),
          Center(child: _CountdownCircle(secondsRemaining: state.secondsRemaining)),
          SizedBox(height: context.sectionSpacing),
          Text(
            'Alerta enviado',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.error,
              fontSize: context.scaleFont(30),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Estamos aguardando alguém da sua rede de apoio aceitar o chamado.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          AppTintedCard(
            tint: AppColors.primary,
            child: Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    taskTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          Text(
            'Avisados agora (${state.notifiedMembers.length})',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
          for (final member in state.notifiedMembers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SosSelectableCard(
                isSelected: false,
                child: SosMemberTile(
                  member: member,
                  statusLabel: 'Notificado agora',
                  statusColor: AppColors.success,
                ),
              ),
            ),
          SizedBox(height: context.sectionSpacing),
          AppButton(
            label: 'Cancelar alerta',
            variant: AppButtonVariant.destructive,
            icon: Icons.close_rounded,
            onPressed: () => _confirmCancellation(context),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Círculo vermelho com os segundos restantes da janela de cancelamento.
class _CountdownCircle extends StatelessWidget {
  const _CountdownCircle({required this.secondsRemaining});

  final int secondsRemaining;

  /// Dimensão própria do componente (Figma), não é token de espaçamento.
  static const double _diameter = 148.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.error,
        boxShadow: AppShadows.accent(AppColors.error),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$secondsRemaining',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textInverse,
              fontSize: context.scaleFont(56),
            ),
          ),
          Text(
            'segundos',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
