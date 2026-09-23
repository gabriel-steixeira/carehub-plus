/*
 * CareHub Plus — Widget Compartilhado / Barra de Mensagem de Chat
 *
 * Campo de escrita e botão de envio, no formato de cápsula. Promovido de
 * `assistants/presentation/widgets/assistant_input_bar.dart` para aqui: o
 * chat com a Cora e o chat entre pessoas reais usam a mesma barra — só o
 * texto de dica e um botão de atalho opcional (ex.: nota de saúde) mudam.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Barra inferior de escrita, reutilizada por todas as telas de chat.
class AppChatInputBar extends StatelessWidget {
  const AppChatInputBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    this.leading,
    this.sendButtonColor,
  });

  /// Controla o texto em edição. O ciclo de vida é de quem cria a barra.
  final TextEditingController controller;

  /// Dica exibida com o campo vazio.
  final String hintText;

  /// Disparado ao tocar em enviar ou ao confirmar no teclado.
  final VoidCallback onSend;

  /// Botão opcional à esquerda do campo (ex.: atalho de nota de saúde).
  final Widget? leading;

  /// Cor sólida opcional do botão de envio quando há texto.
  ///
  /// Quando não informada, o botão mantém o degradê padrão.
  final Color? sendButtonColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: AppShadows.overlay,
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: context.scaleFont(14),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                  fontSize: context.scaleFont(14),
                ),
                border: _capsuleBorder,
                enabledBorder: _capsuleBorder,
                focusedBorder: _capsuleBorder.copyWith(
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _SendButton(
            controller: controller,
            onSend: onSend,
            sendButtonColor: sendButtonColor,
          ),
        ],
      ),
    );
  }

  /// Borda em cápsula, repetida nos três estados do campo.
  OutlineInputBorder get _capsuleBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        borderSide: const BorderSide(color: AppColors.border),
      );
}

/// Botão de envio, desabilitado enquanto não há texto.
///
/// Observa o controller com [ValueListenableBuilder] em vez de `setState`:
/// só o botão reconstrói a cada tecla, não a barra inteira.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.controller,
    required this.onSend,
    this.sendButtonColor,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final Color? sendButtonColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;

        return IconButton(
          onPressed: hasText ? onSend : null,
          tooltip: 'Enviar mensagem',
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasText && sendButtonColor == null
                  ? AppColors.primaryGradient
                  : null,
              color: hasText
                  ? (sendButtonColor ?? AppColors.primary)
                  : AppColors.surfaceVariant,
            ),
            child: Icon(
              Icons.send_rounded,
              color: hasText ? AppColors.textInverse : AppColors.textHint,
              size: AppSpacing.md,
            ),
          ),
        );
      },
    );
  }
}
