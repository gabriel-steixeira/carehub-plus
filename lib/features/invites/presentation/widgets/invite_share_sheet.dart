/*
 * CareHub Plus — Convites / Enviar o convite
 *
 * Aparece depois de salvar o membro: mostra a mensagem pronta e oferece
 * enviar pelo WhatsApp da própria dona (abre a conversa com o membro) ou
 * copiar o texto. O envio sai do aparelho dela, então não usa a cota de
 * mensagens do CareHub.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scroll_fade.dart';
import '../../domain/entities/invite_share_entity.dart';

/// Modal com o convite pronto para enviar.
class InviteShareSheet extends StatelessWidget {
  const InviteShareSheet({super.key, required this.invite});

  final InviteShareEntity invite;

  static Future<void> show(BuildContext context, InviteShareEntity invite) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: context.screenHeight * 0.85),
      builder: (_) => InviteShareSheet(invite: invite),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textInverse),
        ),
        backgroundColor: background,
      ),
    );
  }

  Future<void> _sendByWhatsApp(BuildContext context) async {
    final link = invite.shareLink;
    if (link == null) return;
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Sem WhatsApp no aparelho: cai no aviso para copiar a mensagem.
    }
    if (!context.mounted) return;
    if (opened) {
      Navigator.of(context).pop();
    } else {
      _showSnackBar(
        context,
        'Não consegui abrir o WhatsApp. Copie a mensagem e envie por onde preferir.',
        AppColors.primaryDark,
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.shareText));
    if (context.mounted) {
      _showSnackBar(context, 'Mensagem copiada.', AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expires = DateFormat("dd/MM 'às' HH:mm").format(invite.expiresAt);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Convite pronto',
                style: AppTypography.averiaHeadlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: AppScrollFade(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Código ${invite.code} · vale até $expires · uso único.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: SelectableText(
                          invite.shareText,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (invite.shareLink != null) ...[
                        AppButton(
                          label: 'Enviar pelo WhatsApp',
                          icon: Icons.chat_outlined,
                          onPressed: () => _sendByWhatsApp(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppButton(
                        label: 'Copiar mensagem',
                        icon: Icons.copy_rounded,
                        variant: invite.shareLink != null
                            ? AppButtonVariant.secondary
                            : AppButtonVariant.primary,
                        onPressed: () => _copy(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Fechar',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
