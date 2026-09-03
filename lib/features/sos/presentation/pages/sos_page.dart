/*
 * CareHub Plus — SOS / Página
 *
 * Tela de pedido de ajuda à rede de apoio. Aqui só há composição: cabeçalho,
 * conteúdo da etapa atual do fluxo e navegação inferior. Qual etapa aparece é
 * decisão do `SosBloc`, então a página não guarda nenhuma regra.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/categories/data/repositories/care_categories_repository.dart';
import '../../../../features/categories/presentation/bloc/care_categories_bloc.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../data/repositories/sos_repository.dart';
import '../bloc/sos_bloc.dart';
import '../models/sos_request_args.dart';
import '../widgets/sos_accepted_view.dart';
import '../widgets/sos_alerting_view.dart';
import '../widgets/sos_compose_view.dart';

/// Tela de SOS / pedido de ajuda à rede de apoio.
class SosPage extends StatelessWidget {
  const SosPage({super.key, this.args});

  /// Pré-seleção vinda de outra tela (ex.: arrastar um card em Tarefas).
  final SosRequestArgs? args;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SosBloc(repository: SosRepository())
            ..add(
              SosLoadEvent(
                careRecipientId: args?.careRecipientId,
                taskId: args?.taskId,
              ),
            ),
        ),
        BlocProvider(
          create: (context) =>
              CareCategoriesBloc(repository: CareCategoriesRepository())
                ..add(const CareCategoriesLoadEvent()),
        ),
      ],
      child: SosView(args: args),
    );
  }
}

class SosView extends StatelessWidget {
  const SosView({super.key, this.args});

  /// Mantém a pré-seleção original ao tentar carregar a tela novamente.
  final SosRequestArgs? args;

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.tasks);
      case 2:
        context.push(AppRoutes.coraChat);
      case 3:
        context.push(AppRoutes.chat);
      case 4:
        // Já estamos no SOS.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            BlocSelector<SosBloc, SosState, String?>(
              selector: (state) => state.caregiverPhotoUrl,
              builder: (context, photoUrl) => AppHeader(photoUrl: photoUrl),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: BlocConsumer<SosBloc, SosState>(
                  // Erro pontual (falha ao disparar ou cancelar) aparece em
                  // snackbar para não apagar as escolhas já feitas na tela.
                  listenWhen: (previous, current) =>
                      current.status == SosStatus.ready &&
                      current.errorMessage != null &&
                      previous.errorMessage != current.errorMessage,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.errorMessage!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textInverse,
                          ),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                  builder: (context, state) => switch (state.status) {
                    SosStatus.initial ||
                    SosStatus.loading => const AppLoading(),
                    SosStatus.failure => AppErrorView(
                      message:
                          state.errorMessage ??
                          'Erro ao carregar o pedido de ajuda.',
                      onRetry: () => context.read<SosBloc>().add(
                        SosLoadEvent(
                          careRecipientId: args?.careRecipientId,
                          taskId: args?.taskId,
                        ),
                      ),
                    ),
                    SosStatus.ready => _SosPhaseView(state: state),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}

/// Escolhe o conteúdo conforme a etapa do pedido de ajuda.
class _SosPhaseView extends StatelessWidget {
  const _SosPhaseView({required this.state});

  final SosState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      SosPhase.composing => SosComposeView(state: state),
      SosPhase.alerting => SosAlertingView(state: state),
      SosPhase.accepted => SosAcceptedView(state: state),
    };
  }
}
