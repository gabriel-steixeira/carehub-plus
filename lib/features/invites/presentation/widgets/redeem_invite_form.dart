/*
 * CareHub Plus — Convites / Formulário do código
 *
 * Campo do código, explicação curta e botão. Guarda só o texto digitado;
 * validar e enviar é com o `RedeemInviteBloc`.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Formulário de "Tenho um convite".
class RedeemInviteForm extends StatefulWidget {
  const RedeemInviteForm({
    super.key,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<String> onSubmit;

  @override
  State<RedeemInviteForm> createState() => _RedeemInviteFormState();
}

class _RedeemInviteFormState extends State<RedeemInviteForm> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onSubmit(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Tenho um convite',
          style: AppTypography.averiaHeadlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Digite o código de 6 caracteres que você recebeu. Assim que ele for '
          'aceito, o perfil compartilhado aparece na sua conta.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _codeController,
                label: 'Código do convite',
                hint: 'Ex.: 7F3K9Q',
                prefixIcon: Icons.vpn_key_outlined,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                enabled: !widget.isSubmitting,
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          error,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Usar convite',
                icon: Icons.check_rounded,
                isLoading: widget.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Se você entrou com o mesmo e-mail que a pessoa cadastrou e ele já '
          'está confirmado, o acesso aparece sozinho — não precisa do código.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
