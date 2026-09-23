/*
 * CareHub Plus — SOS / Etapa 3: chamado aceito
 *
 * Última etapa do fluxo: mostra quem da rede de apoio aceitou o pedido, o tempo
 * estimado de chegada e os atalhos de contato. Ligar abre o discador do
 * aparelho; o acompanhamento em mapa ainda não existe nesta versão e a tela diz
 * isso em vez de simular um recurso.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../../shared/widgets/app_tinted_card.dart';
import '../../../network/data/models/network_member_model.dart';
import '../bloc/sos_bloc.dart';
import 'sos_member_tile.dart';

/// Etapa do chamado aceito por alguém da rede de apoio.
class SosAcceptedView extends StatelessWidget {
  const SosAcceptedView({super.key, required this.state});

  final SosState state;

  static const double _badgeDiameter = 132.0;

  Future<void> _call(BuildContext context, NetworkMemberModel member) async {
    final messenger = ScaffoldMessenger.of(context);
    final digits = member.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);

    bool launched;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      // Emulador e alguns aparelhos sem app de telefone lançam exceção.
      launched = false;
    }
    if (launched) return;

    messenger.showSnackBar(
      _snackBar('Não foi possível abrir o discador para ${member.name}.'),
    );
  }

  SnackBar _snackBar(String message) {
    return SnackBar(
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textInverse),
      ),
      backgroundColor: AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = state.acceptedMember;
    final etaMinutes = state.acceptance?.etaMinutes ?? 0;

    if (member == null) {
      return const AppEmptyView(
        message: 'Não foi possível identificar quem aceitou o chamado.',
        icon: Icons.person_search_rounded,
      );
    }

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: context.sectionSpacing),
          Center(
            child: Container(
              width: _badgeDiameter,
              height: _badgeDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: AppShadows.accent(AppColors.success),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 64,
                color: AppColors.textInverse,
              ),
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          Text(
            'SOS confirmado',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.success,
              fontSize: context.scaleFont(30),
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: SosMemberTile(member: member)),
                    _CircleIconButton(
                      icon: Icons.call_rounded,
                      tooltip: 'Ligar para ${member.name}',
                      onPressed: () => _call(context, member),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CircleIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      tooltip: 'Conversar com ${member.name}',
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        _snackBar(
                          'A conversa direta pelo SOS entra em uma próxima '
                          'versão.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.smMd),
                Text(
                  '${member.name} aceitou o chamado e deve chegar em '
                  'aproximadamente $etaMinutes minutos.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          AppTintedCard(
            tint: AppColors.info,
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'O acompanhamento da chegada em tempo real ainda não está '
                    'disponível nesta versão.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          AppButton(
            label: 'Encerrar pedido de ajuda',
            icon: Icons.task_alt_rounded,
            onPressed: () =>
                context.read<SosBloc>().add(const SosAlertRestartedEvent()),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Botão circular de contato (ligar, conversar).
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  static const double _diameter = 44.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: _diameter,
        height: _diameter,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.primaryDark,
          ),
          icon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
