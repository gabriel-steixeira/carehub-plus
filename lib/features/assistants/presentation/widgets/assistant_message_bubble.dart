/*
 * CareHub Plus — Apresentação / Bolha de Mensagem
 *
 * Desenha uma mensagem da conversa: avatar, bolha com cauda do lado de quem
 * falou, horário e, quando o assistente sugere caminhos, os chips de resposta
 * rápida. Não decide nada — só exibe o que a entidade já traz.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_chat_avatar.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../models/assistant_profile.dart';
import 'assistant_quick_reply_chip.dart';

/// Bolha de uma mensagem do chat de assistente.
class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.message,
    required this.profile,
    required this.onQuickReplyTap,
    this.caregiverPhotoUrl,
  });

  /// Mensagem exibida.
  final AssistantMessage message;

  /// Identidade do agente — define avatar e nome anunciado por leitores de tela.
  final AssistantProfile profile;

  /// Foto do cuidador logado, a mesma exibida no `AppHeader`.
  final String? caregiverPhotoUrl;

  /// Disparado quando a cuidadora toca em um atalho sugerido.
  final ValueChanged<AssistantQuickReply> onQuickReplyTap;

  /// Horário no formato 24h usado no Brasil.
  String get _formattedTime {
    final hour = message.timestamp.hour.toString().padLeft(2, '0');
    final minute = message.timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    final avatarColumnWidth = AppChatAvatar.columnWidth(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: isFromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isFromUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isFromUser)
                // Reserva a mesma coluna ocupada pelo avatar do assistente, para
                // que as duas bolhas comecem na mesma margem esquerda.
                SizedBox(width: avatarColumnWidth)
              else ...[
                AppChatAvatar.asset(assetPath: profile.avatarAsset),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: _buildBubble(context, isFromUser: isFromUser)),
              if (isFromUser) ...[
                const SizedBox(width: AppSpacing.xs),
                AppChatAvatar.photo(photoUrl: caregiverPhotoUrl),
              ],
            ],
          ),
          if (!isFromUser && message.quickReplies.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: EdgeInsets.only(left: avatarColumnWidth),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: message.quickReplies
                    .map(
                      (quickReply) => AssistantQuickReplyChip(
                        quickReply: quickReply,
                        accentColor: profile.accentColor,
                        onTap: onQuickReplyTap,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, {required bool isFromUser}) {
    // Leitores de tela anunciam a autoria antes do conteúdo.
    final author = isFromUser ? 'Você' : profile.name;
    final userBubbleColor = profile.accentColor ?? AppColors.primary;

    return Semantics(
      label: '$author, às $_formattedTime',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isFromUser ? userBubbleColor : AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusLg),
            topRight: const Radius.circular(AppSpacing.radiusLg),
            bottomLeft: Radius.circular(
              isFromUser ? AppSpacing.radiusLg : AppSpacing.radiusXs,
            ),
            bottomRight: Radius.circular(
              isFromUser ? AppSpacing.radiusXs : AppSpacing.radiusLg,
            ),
          ),
          boxShadow: AppShadows.raised,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTypography.bodyMedium.copyWith(
                color: isFromUser
                    ? AppColors.textInverse
                    : AppColors.textPrimary,
                fontSize: context.scaleFont(14),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.bottomRight,
              child: ExcludeSemantics(
                child: Text(
                  _formattedTime,
                  style: AppTypography.labelSmall.copyWith(
                    color: isFromUser
                        ? AppColors.textInverse.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    fontSize: context.scaleFont(10),
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
