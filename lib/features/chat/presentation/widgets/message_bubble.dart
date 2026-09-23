/*
 * CareHub Plus — Apresentação / Bolha de Mensagem do Chat Real
 *
 * Bolha de uma conversa entre pessoas reais (cuidador, médico, rede de
 * apoio). Usa o mesmo avatar compartilhado do chat da Cora (`AppChatAvatar`)
 * e a cor da categoria do assunto no lugar de uma cor fixa — assim o card de
 * cada assunto e suas mensagens combinam visualmente.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_chat_avatar.dart';
import '../../data/models/chat_message_model.dart';

/// Bolha de uma mensagem do chat entre pessoas reais.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.accentColor,
    this.senderAvatarUrl,
    this.caregiverAvatarUrl,
    this.caregiverAvatarBase64,
  });

  final ChatMessageModel message;

  /// Cor de destaque do assunto (categoria), usada na bolha própria e no
  /// selo de nota de saúde.
  final Color accentColor;

  /// Foto de quem enviou, quando a mensagem não é do cuidador logado.
  final String? senderAvatarUrl;

  /// Foto do cuidador logado (URL), usada quando a mensagem é dele próprio.
  final String? caregiverAvatarUrl;

  /// Foto do cuidador logado (base64), usada quando não há URL disponível.
  final String? caregiverAvatarBase64;

  String get _time {
    final t = message.timestamp;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Retorna a foto do cuidador, priorizando a URL, mas usando base64 como
  /// fallback se necessário.
  String? get _caregiverPhoto {
    if (caregiverAvatarUrl != null && caregiverAvatarUrl!.isNotEmpty) {
      return caregiverAvatarUrl;
    }
    return caregiverAvatarBase64;
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isMedicalNote = message.type == ChatMessageType.medicalNote;
    final avatarColumnWidth = AppChatAvatar.columnWidth(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe)
            SizedBox(width: avatarColumnWidth)
          else ...[
            AppChatAvatar.photo(photoUrl: senderAvatarUrl),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isMedicalNote
                    ? accentColor.withValues(alpha: 0.12)
                    : isMe
                        ? accentColor
                        : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLg),
                  topRight: const Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(
                    isMe ? AppSpacing.radiusLg : AppSpacing.radiusXs,
                  ),
                  bottomRight: Radius.circular(
                    isMe ? AppSpacing.radiusXs : AppSpacing.radiusLg,
                  ),
                ),
                border: isMedicalNote
                    ? Border.all(color: accentColor, width: 1.5)
                    : isMe
                        ? null
                        : Border.all(color: AppColors.border),
                boxShadow: AppShadows.raised,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.senderName,
                      style: AppTypography.labelSmall.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (isMedicalNote) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Registro de Saúde / Cuidados',
                          style: AppTypography.labelSmall.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isMe ? AppColors.textInverse : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _time,
                    style: AppTypography.labelSmall.copyWith(
                      color: isMe
                          ? AppColors.textInverse.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: AppSpacing.xs),
            AppChatAvatar.photo(photoUrl: _caregiverPhoto),
          ],
        ],
      ),
    );
  }
}
