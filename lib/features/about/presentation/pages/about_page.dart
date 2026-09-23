/*
 * CareHub Plus — Apresentação / Página Sobre
 *
 * Exibe o conteúdo institucional do aplicativo com carregamento remoto e
 * estados de erro e conteúdo vazio, seguindo o frame padrão das páginas.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../data/repositories/about_repository.dart';
import '../bloc/about_bloc.dart';
import '../widgets/about_content.dart';

/// Página institucional do CareHub+.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: BlocProvider(
          create: (_) =>
              AboutBloc(repository: AboutRepository())
                ..add(const AboutLoadEvent()),
          child: const _AboutView(),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  static void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.tasks);
      case 2:
        context.go(AppRoutes.coraChat);
      case 3:
        context.go(AppRoutes.chat);
      case 4:
        context.go(AppRoutes.sos);
    }
  }
}

class _AboutView extends StatelessWidget {
  const _AboutView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AboutBloc, AboutState>(
      builder: (context, state) {
        return Column(
          children: [
            AppHeader(
              showSettings: false,
              leading: IconButton(
                onPressed: () => context.go(AppRoutes.settings),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Voltar para configurações',
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: _AboutBody(state: state),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody({required this.state});

  final AboutState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case AboutStatus.initial:
      case AboutStatus.loading:
        return const AppLoading();
      case AboutStatus.failure:
        return AppErrorView(
          message:
              state.errorMessage ??
              'Não foi possível carregar o conteúdo Sobre.',
          onRetry: () => context.read<AboutBloc>().add(const AboutLoadEvent()),
        );
      case AboutStatus.success:
        final content = state.content;
        if (content == null || !content.hasContent) {
          return const AppEmptyView(
            message: 'O conteúdo Sobre ainda não está disponível.',
            icon: Icons.info_outline_rounded,
          );
        }
        return AboutContent(content: content);
    }
  }
}
