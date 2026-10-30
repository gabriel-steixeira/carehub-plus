/*
 * CareHub Plus — Convites / Enviar o convite
 *
 * Aparece depois de salvar o membro: mostra o código em destaque e as formas
 * de enviar o convite — pelo app (folha de compartilhamento do sistema), por
 * e-mail, pelo WhatsApp da própria dona, ou apenas informando o código para a
 * pessoa digitar em "Tenho um convite". Todo envio sai do aparelho dela, então
 * não usa a cota de mensagens do CareHub.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.1.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Abre a folha de compartilhamento do sistema (WhatsApp, Telegram, e-mail,
  /// o que a dona preferir) já com a mensagem pronta.
  Future<void> _sendByApp(BuildContext context) async {
    try {
      await Share.share(invite.shareText, subject: 'Convite do CareHub Plus');
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Não consegui abrir o compartilhamento. Copie a mensagem e envie '
          'por onde preferir.',
          AppColors.primaryDark,
        );
      }
    }
  }

  /// Abre o app de e-mail da dona com assunto e mensagem já preenchidos.
  Future<void> _sendByEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      query: _encodeQuery({
        'subject': 'Convite do CareHub Plus',
        'body': invite.shareText,
      }),
    );
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Sem app de e-mail: cai no aviso para copiar a mensagem.
    }
    if (!context.mounted) return;
    if (!opened) {
      _showSnackBar(
        context,
        'Não consegui abrir o e-mail. Copie a mensagem e envie por onde '
        'preferir.',
        AppColors.primaryDark,
      );
    }
  }

  /// `Uri` não codifica os espaços como `mailto` espera; fazemos manualmente.
  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map(
          (entry) =>
              '${entry.key}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
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

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.shareText));
    if (context.mounted) {
      _showSnackBar(context, 'Mensagem copiada.', AppColors.success);
    }
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.code));
    if (context.mounted) {
      _showSnackBar(context, 'Código copiado.', AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expires = DateFormat("dd/MM 'às' HH:mm").format(invite.expiresAt);
    final hasWhatsApp = invite.shareLink != null;

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
                      // ── Código em destaque ───────────────────────────────
                      _CodeBox(
                        code: invite.code,
                        onCopy: () => _copyCode(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Vale até $expires · uso único. A pessoa digita este '
                        'código em "Tenho um convite", no app.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Mensagem pronta ──────────────────────────────────
                      Text(
                        'Mensagem pronta',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
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

                      // ── Como enviar ──────────────────────────────────────
                      Text(
                        'Como enviar',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (hasWhatsApp) ...[
                        AppButton(
                          label: 'Enviar pelo WhatsApp',
                          icon: Icons.chat_outlined,
                          onPressed: () => _sendByWhatsApp(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppButton(
                        label: 'Enviar pelo app',
                        icon: Icons.ios_share_rounded,
                        variant: hasWhatsApp
                            ? AppButtonVariant.secondary
                            : AppButtonVariant.primary,
                        onPressed: () => _sendByApp(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Enviar por e-mail',
                        icon: Icons.email_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _sendByEmail(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Copiar mensagem',
                        icon: Icons.copy_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _copyMessage(context),
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

/// Caixa com o código em destaque e um atalho para copiar só o código.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código do convite',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  code,
                  style: AppTypography.averiaHeadlineMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'Copiar código',
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
