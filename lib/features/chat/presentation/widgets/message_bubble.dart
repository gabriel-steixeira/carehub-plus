import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/chat_message_model.dart';

/// Message bubble with sender, timestamp, and special styling for medical notes.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessageModel message;

  String get _time {
    final t = message.timestamp;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isMedicalNote = message.type == ChatMessageType.medicalNote;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isMedicalNote
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : isMe
                  ? AppColors.primary
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusLg),
            topRight: const Radius.circular(AppSpacing.radiusLg),
            bottomLeft: Radius.circular(isMe ? AppSpacing.radiusLg : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusLg),
          ),
          border: isMedicalNote
              ? Border.all(color: AppColors.primary, width: 1.5)
              : isMe
                  ? null
                  : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: AppTypography.labelSmall.copyWith(
                  color: isMedicalNote
                      ? AppColors.primaryDark
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
            ],

            if (isMedicalNote) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Registro de Saúde / Cuidados',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
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
                color: isMe
                    ? Colors.white
                    : isMedicalNote
                        ? AppColors.textPrimary
                        : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              _time,
              style: AppTypography.labelSmall.copyWith(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
