import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/register_form.dart';

/// Register page — provides [AuthBloc] and renders the registration UI.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(repository: context.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cadastro realizado com sucesso! Faça login para continuar.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(AppRoutes.login);
          }
        },
        child: AppPageFrame(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
            child: Column(
              children: [
                const AppHeader(showProfile: false, showSettings: false),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: context.scaleSpacing(AppSpacing.lg)),

                        // Title and subtitle
                        Text(
                          'Crie sua conta',
                          textAlign: TextAlign.center,
                          style: AppTypography.averiaTitleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: context.scaleFont(32),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Preencha os detalhes abaixo para começar.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Register card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const RegisterForm(),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Login link (outside/below the card)
                        const _LoginLink(),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Já tem uma conta? ',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      context.go(AppRoutes.login);
                    },
              child: Text(
                'Entre',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
