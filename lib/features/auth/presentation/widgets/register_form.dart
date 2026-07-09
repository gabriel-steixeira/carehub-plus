import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import 'social_login_buttons.dart';

/// Register form widget with name, email, password, confirm password, terms check, and social options.
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() {
      _showTermsError = !_termsAccepted;
    });

    if ((_formKey.currentState?.validate() ?? false) && _termsAccepted) {
      context.read<AuthBloc>().add(
        AuthSignUpSubmitted(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nome Completo field
              AppTextField(
                controller: _nameController,
                label: 'Nome Completo',
                hint: 'Seu nome completo',
                prefixIcon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (val) => Validators.required(val, 'nome completo'),
                enabled: !isLoading,
              ),

              const SizedBox(height: AppSpacing.md),

              // Email field
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'nome@exemplo.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !isLoading,
              ),

              const SizedBox(height: AppSpacing.md),

              // Password field
              AppTextField(
                controller: _passwordController,
                label: 'Senha',
                hint: 'Sua senha segura',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                validator: Validators.password,
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Confirm Password field
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirmar Senha',
                hint: 'Repita sua senha',
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: (val) {
                  if (val != _passwordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return Validators.required(val, 'confirmar senha');
                },
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Checkbox + Terms text
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _termsAccepted,
                      activeColor: AppColors.primary,
                      side: BorderSide(
                        color: _showTermsError
                            ? AppColors.error
                            : AppColors.border,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXs,
                        ),
                      ),
                      onChanged: isLoading
                          ? null
                          : (val) {
                              setState(() {
                                _termsAccepted = val ?? false;
                                if (_termsAccepted) {
                                  _showTermsError = false;
                                }
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        children: [
                          const TextSpan(text: 'Eu aceito os '),
                          TextSpan(
                            text: 'Termos de Serviço',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Navigate to Terms of Service
                              },
                          ),
                          const TextSpan(text: ' e a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Navigate to Privacy Policy
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Terms error message
              if (_showTermsError) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 32.0),
                  child: Text(
                    'Você deve aceitar os termos e políticas para prosseguir',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Error from bloc state
              if (state.status == AuthStatus.failure &&
                  state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // SignUp button
              AppButton(
                label: 'Cadastrar',
                onPressed: _onSubmit,
                isLoading: isLoading,
                icon: Icons.arrow_forward_rounded,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.textHint)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'OU USE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.textHint)),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Social logins
              SocialLoginButtons(
                enabled: !isLoading,
                onGooglePressed: () {
                  context.read<AuthBloc>().add(
                    const AuthGoogleSignInRequested(),
                  );
                },
                onFacebookPressed: () {
                  context.read<AuthBloc>().add(
                    const AuthFacebookSignInRequested(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}
