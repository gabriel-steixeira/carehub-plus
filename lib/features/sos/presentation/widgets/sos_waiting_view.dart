/*
 * CareHub Plus — SOS / Etapa 3: aguardando resposta
 *
 * O aviso já saiu pelo WhatsApp e a tela mostra há quanto tempo a rede foi
 * avisada e a situação de cada pessoa (aguardando, recusou, falha no envio).
 * As respostas chegam em tempo real pelo `SosBloc`; esta tela só desenha.
 * Quando ninguém pode atender, oferece montar um novo pedido.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
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
import '../../../network/data/models/network_member_model.dart';
import '../bloc/sos_bloc.dart';
import 'sos_cancel_confirmation_sheet.dart';
import 'sos_member_tile.dart';
import 'sos_selectable_card.dart';

/// Etapa de espera pela resposta da rede de apoio.
class SosWaitingView extends StatelessWidget {
  const SosWaitingView({super.key, required this.state});

  final SosState state;

  Future<void> _confirmCancellation(BuildContext context) async {
    final bloc = context.read<SosBloc>();
    final messenger = ScaffoldMessenger.of(context);

    final isConfirmed = await SosCancelConfirmationSheet.show(context);
    if (!isConfirmed) return;

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

  /// Situação de um avisado, para a legenda da linha.
  ({String label, Color color}) _memberStatus(NetworkMemberModel member) {
    final snapshot = state.alertSnapshot;
    if (snapshot != null && snapshot.hasDeclined(member.id)) {
      return (label: 'Não pode ajudar agora', color: AppColors.error);
    }
    if (snapshot != null && snapshot.deliveryFailedForAll) {
      return (label: 'Falha no envio pelo WhatsApp', color: AppColors.warning);
    }
    return (label: 'Aguardando resposta', color: AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = state.alertSnapshot;
    final taskTitle = state.selectedTask?.title ?? 'Tarefa de cuidado';
    final isOver = state.isWaitingOver;
    final deliveryFailed = snapshot?.deliveryFailedForAll ?? false;

    final title = deliveryFailed
        ? 'Aviso não enviado'
        : state.everyoneDeclined
        ? 'Ninguém pode ajudar agora'
        : 'Aguardando resposta';
    final subtitle = deliveryFailed
        ? 'Não conseguimos avisar sua rede pelo WhatsApp. Ligue para alguém '
              'ou tente enviar de novo.'
        : state.everyoneDeclined
        ? 'Todas as pessoas avisadas responderam que não podem. Ligue para '
              'alguém ou monte um novo pedido.'
        : 'Sua rede foi avisada pelo WhatsApp. A tela muda assim que alguém '
              'aceitar.';

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: context.sectionSpacing),
          Center(
            child: _ElapsedCircle(
              seconds: state.secondsWaiting,
              color: isOver ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: isOver ? AppColors.error : AppColors.primaryDark,
              fontSize: context.scaleFont(30),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (snapshot?.deliveryFailedForSome ?? false) ...[
            SizedBox(height: context.sectionSpacing),
            AppTintedCard(
              tint: AppColors.warning,
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${snapshot!.whatsappFailed} aviso(s) não puderam ser '
                      'enviados pelo WhatsApp.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            'Avisados (${state.notifiedMembers.length})',
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
                child: Builder(
                  builder: (context) {
                    final status = _memberStatus(member);
                    return SosMemberTile(
                      member: member,
                      statusLabel: status.label,
                      statusColor: status.color,
                    );
                  },
                ),
              ),
            ),
          SizedBox(height: context.sectionSpacing),
          if (isOver)
            AppButton(
              label: 'Montar novo pedido',
              icon: Icons.refresh_rounded,
              // Encerra o alerta atual no Firestore e volta à montagem.
              onPressed: () =>
                  context.read<SosBloc>().add(const SosAlertCancelledEvent()),
            )
          else
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

/// Círculo com o tempo decorrido desde o envio do aviso (mm:ss).
class _ElapsedCircle extends StatelessWidget {
  const _ElapsedCircle({required this.seconds, required this.color});

  final int seconds;
  final Color color;

  /// Mesma dimensão do círculo da contagem regressiva, para a transição entre
  /// as etapas não "pular".
  static const double _diameter = 148.0;

  String get _formatted {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: AppShadows.accent(color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatted,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textInverse,
              fontSize: context.scaleFont(40),
            ),
          ),
          Text(
            'aguardando',
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
