/*
 * CareHub Plus — Configurações / Aviso de exclusão de conta (Passo 1)
 *
 * Primeiro passo do fluxo de excluir a conta: explica, por caso, o que será
 * removido antes de pedir a senha. Excluir é irreversível, então a ação de
 * continuar vem depois do aviso e "Cancelar" fecha o fluxo sem risco.
 *
 * Devolve `true` quando a cuidadora decide seguir para a reautenticação.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/delete_account_preview.dart';

/// Bottom sheet de aviso (Passo 1) do fluxo de exclusão de conta.
class DeleteAccountWarningSheet extends StatelessWidget {
  const DeleteAccountWarningSheet({super.key, required this.preview});

  /// Prévia resolvida que define a mensagem exibida.
  final DeleteAccountPreview preview;

  static const double _handleWidth = 40.0;
  static const double _iconBadgeSize = 72.0;

  /// Abre o sheet e devolve `true` se a cuidadora optar por continuar.
  static Future<bool> show(
    BuildContext context, {
    required DeleteAccountPreview preview,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DeleteAccountWarningSheet(preview: preview),
    );
    return confirmed ?? false;
  }

  String get _title => 'Excluir conta?';

  String get _message {
    switch (preview.deletionCase) {
      case DeletionCase.soloOrGrantee:
        return 'Sua conta será excluída junto com os seus dados pessoais. '
            'Esta ação é permanente e não pode ser desfeita.';
      case DeletionCase.ownerNoOthers:
        return 'Como ninguém mais acompanha os seus perfis de cuidado, tudo '
            'relacionado a eles será excluído: tarefas, conversas, membros da '
            'rede de apoio e alertas. Esta ação é permanente e não pode ser '
            'desfeita.';
      case DeletionCase.ownerWithOthers:
        return 'Você é a responsável principal e outras pessoas acompanham os '
            'seus perfis de cuidado. Ao excluir a sua conta, tudo relacionado '
            'será removido — inclusive o acesso dessas pessoas. Esta ação é '
            'permanente e não pode ser desfeita.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final affected = preview.affectedNames;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _handleWidth,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                width: _iconBadgeSize,
                height: _iconBadgeSize,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (preview.deletionCase == DeletionCase.ownerWithOthers &&
                affected.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _AffectedNamesPanel(names: affected),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Continuar',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista os nomes de quem perde o acesso quando a dona exclui a conta.
class _AffectedNamesPanel extends StatelessWidget {
  const _AffectedNamesPanel({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPanel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perderão o acesso:',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_remove_outlined,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
