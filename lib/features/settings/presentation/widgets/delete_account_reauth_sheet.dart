/*
 * CareHub Plus — Configurações / Reautenticação de exclusão (Passo 2)
 *
 * Segundo passo do fluxo de excluir a conta: confirma a identidade antes de
 * apagar nada. O backend exige login recente, então pedimos a senha (ou o
 * login social, conforme o provedor da conta). Só devolve `true` quando a
 * reautenticação dá certo — aí a página dispara a exclusão.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Bottom sheet de reautenticação (Passo 2) do fluxo de exclusão de conta.
class DeleteAccountReauthSheet extends StatefulWidget {
  const DeleteAccountReauthSheet({super.key, this.authService});

  /// Serviço de autenticação; injetável para testes.
  final AuthService? authService;

  static const double _handleWidth = 40.0;

  /// Abre o sheet e devolve `true` quando a reautenticação é concluída.
  static Future<bool> show(
    BuildContext context, {
    AuthService? authService,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DeleteAccountReauthSheet(authService: authService),
    );
    return confirmed ?? false;
  }

  @override
  State<DeleteAccountReauthSheet> createState() =>
      _DeleteAccountReauthSheetState();
}

class _DeleteAccountReauthSheetState extends State<DeleteAccountReauthSheet> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _usesPassword =>
      _authService.currentProviderIds.contains('password');

  bool get _usesGoogle =>
      _authService.currentProviderIds.contains('google.com');

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() reauth) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await reauth();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível confirmar agora. Tente novamente.';
      });
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Senha incorreta. Verifique e tente de novo.';
      case 'ERROR_ABORTED_BY_USER':
        return 'Confirmação cancelada. Nenhum dado foi excluído.';
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet e tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um instante e tente de novo.';
      default:
        return 'Não foi possível confirmar agora. Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
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
                width: DeleteAccountReauthSheet._handleWidth,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Confirme sua identidade',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Por segurança, confirme seu acesso antes de excluir a conta '
              'definitivamente.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: AppLoading(),
              )
            else ...[
              ..._buildReauthControls(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReauthControls() {
    if (_usesPassword) {
      return [
        AppTextField(
          controller: _passwordController,
          label: 'Senha',
          hint: 'Digite sua senha',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Excluir definitivamente',
          variant: AppButtonVariant.destructive,
          icon: Icons.delete_forever_rounded,
          onPressed: () => _run(
            () => _authService.reauthenticateWithPassword(
              _passwordController.text,
            ),
          ),
        ),
      ];
    }

    if (_usesGoogle) {
      return [
        AppButton(
          label: 'Confirmar com Google',
          variant: AppButtonVariant.destructive,
          icon: Icons.login_rounded,
          onPressed: () => _run(_authService.reauthenticateWithGoogle),
        ),
      ];
    }

    return [
      Text(
        'Não foi possível identificar o seu método de login. '
        'Entre novamente no app e tente outra vez.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ];
  }
}
