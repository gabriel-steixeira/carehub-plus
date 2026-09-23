/*
 * CareHub Plus — Perfil / Página de Edição
 *
 * Tela de edição dos dados do cuidador, aberta pelo botão "Editar" das
 * Configurações. Aqui só há composição: cabeçalho, corpo conforme o estado do
 * `EditProfileBloc` e navegação inferior — nenhuma regra de negócio.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../data/repositories/caregiver_profile_repository.dart';
import '../bloc/edit_profile_bloc.dart';
import '../widgets/edit_profile_form.dart';

/// Tela de edição do perfil do cuidador.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EditProfileBloc(repository: CaregiverProfileRepository())
            ..add(const EditProfileLoadEvent()),
      child: const EditProfileView(),
    );
  }
}

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.push(AppRoutes.tasks);
      case 2:
        context.push(AppRoutes.coraChat);
      case 3:
        context.push(AppRoutes.chat);
      case 4:
        context.push(AppRoutes.sos);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required Color background,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: background,
        ),
      );
  }

  /// Recursos que dependem de telas ainda não construídas.
  void _showComingSoon(BuildContext context, String label) {
    _showSnackBar(
      context,
      '$label estará disponível em breve.',
      background: AppColors.primaryDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            BlocSelector<EditProfileBloc, EditProfileState, String?>(
              selector: (state) => state.profile?.photoUrl,
              builder: (context, photoUrl) => AppHeader(photoUrl: photoUrl),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: BlocConsumer<EditProfileBloc, EditProfileState>(
                  // Só o resultado da gravação vira aviso: o erro de
                  // carregamento já ocupa a tela inteira com o AppErrorView.
                  listenWhen: (previous, current) =>
                      previous.saveStatus != current.saveStatus,
                  listener: (context, state) {
                    switch (state.saveStatus) {
                      case EditProfileSaveStatus.success:
                        _showSnackBar(
                          context,
                          'Perfil atualizado.',
                          background: AppColors.success,
                        );
                        // Volta para de onde veio (Configurações) só quando há
                        // rota anterior — a tela também pode ser aberta direto.
                        if (context.canPop()) context.pop();
                      case EditProfileSaveStatus.failure:
                        _showSnackBar(
                          context,
                          state.errorMessage ??
                              'Não foi possível salvar seu perfil.',
                          background: AppColors.error,
                        );
                      case EditProfileSaveStatus.idle:
                      case EditProfileSaveStatus.saving:
                        break;
                    }
                  },
                  builder: (context, state) {
                    if (state.status == EditProfileStatus.initial ||
                        state.status == EditProfileStatus.loading) {
                      return const AppLoading();
                    }

                    final profile = state.profile;
                    final plan = state.plan;

                    if (state.status == EditProfileStatus.failure ||
                        profile == null) {
                      return AppErrorView(
                        message:
                            state.errorMessage ??
                            'Erro ao carregar seu perfil.',
                        onRetry: () => context.read<EditProfileBloc>().add(
                          const EditProfileLoadEvent(),
                        ),
                      );
                    }

                    // Não há estado vazio próprio: uma conta sem dados abre o
                    // formulário com os campos em branco para preencher.
                    return AppResponsiveBody(
                      child: EditProfileForm(
                        profile: profile,
                        plan: plan,
                        contractedSubscription: state.contractedSubscription,
                        onPrivacyTap: () =>
                            _showComingSoon(context, 'Privacidade dos dados'),
                        onChangePlan: () =>
                            context.push(AppRoutes.subscriptions),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        // A tela é aberta pelas Configurações, então nenhuma aba fica marcada.
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}
