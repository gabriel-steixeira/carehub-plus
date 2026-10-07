/*
 * CareHub Plus — Perfil / Cartão "Cora no WhatsApp e convites"
 *
 * Dois atalhos no perfil: ligar o próprio WhatsApp à conta (para falar com a
 * Cora e pedir SOS por lá) e abrir "Tenho um convite". Ligar o WhatsApp abre
 * o app de mensagens já com "ENTRAR <código>" escrito — é a própria pessoa
 * que envia, então a Meta confirma que o número é dela.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../invites/data/repositories/invites_repository.dart';
import '../../../invites/presentation/bloc/whatsapp_link_bloc.dart';
import 'profile_icon_badge.dart';

/// Atalhos de WhatsApp e convites no perfil.
class CoraWhatsAppCard extends StatelessWidget {
  const CoraWhatsAppCard({super.key, this.repository});

  /// Permite trocar por um dublê nos testes.
  final InvitesRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WhatsAppLinkBloc(repository: repository ?? InvitesRepository()),
      child: const _CoraWhatsAppCardView(),
    );
  }
}

class _CoraWhatsAppCardView extends StatelessWidget {
  const _CoraWhatsAppCardView();

  void _showSnackBar(BuildContext context, String message, Color background) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: background,
          duration: const Duration(seconds: 8),
        ),
      );
  }

  Future<void> _openWhatsApp(BuildContext context, WhatsAppLinkState state) async {
    final link = state.link;
    if (link == null) return;

    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(link.link),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Emulador sem WhatsApp lança exceção: cai no aviso com o código.
    }
    if (!opened && context.mounted) {
      _showSnackBar(
        context,
        'Não consegui abrir o WhatsApp. Envie "ENTRAR ${link.code}" para o '
        'número do CareHub em até 10 minutos.',
        AppColors.primaryDark,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhatsAppLinkBloc, WhatsAppLinkState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case WhatsAppLinkStatus.ready:
            _openWhatsApp(context, state);
          case WhatsAppLinkStatus.failure:
            _showSnackBar(
              context,
              state.errorMessage ?? 'Não foi possível gerar o código agora.',
              AppColors.error,
            );
          case WhatsAppLinkStatus.initial:
          case WhatsAppLinkStatus.loading:
            break;
        }
      },
      builder: (context, state) {
        final isLoading = state.status == WhatsAppLinkStatus.loading;
        return AppCard(
          variant: AppCardVariant.outlined,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.chat_outlined,
                title: 'Ativar Cora no WhatsApp',
                subtitle:
                    'Fale com a Cora, crie tarefas e peça SOS pelo seu '
                    'WhatsApp. Abrimos a conversa com a mensagem pronta.',
                trailing: isLoading ? const AppLoading(size: 20) : null,
                onTap: isLoading
                    ? null
                    : () => context.read<WhatsAppLinkBloc>().add(
                        const WhatsAppLinkRequestedEvent(),
                      ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ActionRow(
                icon: Icons.vpn_key_outlined,
                title: 'Tenho um convite',
                subtitle: 'Use o código que alguém da família enviou para você.',
                onTap: () => context.push(AppRoutes.redeemInvite),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ProfileIconBadge(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}
