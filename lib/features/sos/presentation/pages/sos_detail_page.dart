/*
 * CareHub Plus — SOS / Página de detalhe do pedido
 *
 * Tela aberta ao tocar na notificação de SOS. Mostra quem pediu ajuda, para
 * qual perfil cuidado, a tarefa relacionada e o horário, e oferece o aceite
 * ("Estou a caminho") a quem foi acionado. Aqui só há composição: quem decide
 * o que exibir e quando aceitar é o `SosDetailBloc`.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_helper.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../data/repositories/sos_repository.dart';
import '../../domain/entities/sos_alert_detail_entity.dart';
import '../../domain/entities/sos_alert_snapshot_entity.dart';
import '../bloc/sos_detail_bloc.dart';

/// Tela de detalhe de um pedido de ajuda (aberta pela notificação de SOS).
class SosDetailPage extends StatelessWidget {
  const SosDetailPage({super.key, required this.alertId});

  /// Id do alerta a carregar, vindo da navegação (`state.extra`).
  final String alertId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SosDetailBloc(repository: SosRepository())
        ..add(SosDetailLoadRequested(alertId)),
      child: _SosDetailView(alertId: alertId),
    );
  }
}

class _SosDetailView extends StatelessWidget {
  const _SosDetailView({required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: BlocBuilder<SosDetailBloc, SosDetailState>(
                builder: (context, state) => switch (state.status) {
                  SosDetailStatus.initial ||
                  SosDetailStatus.loading => const AppLoading(),
                  SosDetailStatus.failure when state.detail == null =>
                    AppErrorView(
                      message:
                          state.errorMessage ??
                          'Não foi possível abrir o pedido de ajuda.',
                      onRetry: () => context.read<SosDetailBloc>().add(
                        SosDetailLoadRequested(alertId),
                      ),
                    ),
                  _ => _SosDetailContent(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Conteúdo da tela quando o detalhe já está carregado.
class _SosDetailContent extends StatelessWidget {
  const _SosDetailContent({required this.state});

  final SosDetailState state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;
    final isAccepting = state.status == SosDetailStatus.accepting;
    final isAccepted =
        state.status == SosDetailStatus.accepted ||
        detail.status == SosAlertStatus.accepted;
    final isFinished =
        detail.status == SosAlertStatus.cancelled ||
        detail.status == SosAlertStatus.unknown;

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pedido de ajuda',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.person_rounded,
                  label: 'Quem pediu',
                  value: detail.requestedByName ?? 'A responsável pelo perfil',
                ),
                if (detail.taskTitle != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(
                    icon: Icons.task_alt_rounded,
                    label: 'Tarefa relacionada',
                    value: detail.taskTitle!,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Quando',
                  value: DateFormatHelper.formatWithTime(detail.createdAt),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(
                  icon: Icons.flag_rounded,
                  label: 'Situação',
                  value: _statusLabel(detail),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isAccepted)
            AppCard(
              variant: AppCardVariant.filled,
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Você confirmou que está a caminho. Quem pediu já foi '
                      'avisado.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!isFinished)
            AppButton(
              label: 'Estou a caminho',
              icon: Icons.directions_run_rounded,
              isLoading: isAccepting,
              onPressed: () => context.read<SosDetailBloc>().add(
                const SosDetailAcceptRequested(),
              ),
            ),
          if (state.status == SosDetailStatus.failure &&
              state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Frase curta que descreve a etapa atual do pedido.
  String _statusLabel(SosAlertDetailEntity detail) {
    return switch (detail.status) {
      SosAlertStatus.pending => 'Aguardando envio para a rede de apoio.',
      SosAlertStatus.dispatched => 'Avisado à rede de apoio, aguardando ajuda.',
      SosAlertStatus.accepted => 'Ajuda a caminho.',
      SosAlertStatus.cancelled => 'Pedido cancelado.',
      SosAlertStatus.unknown => 'Situação indisponível.',
    };
  }
}

/// Linha de "rótulo + valor" com ícone, usada nos detalhes do pedido.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
