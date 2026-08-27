/*
 * CareHub Plus — Assinaturas / Página de Planos
 *
 * Compõe cabeçalho, estados da feature, conteúdo responsivo e navegação padrão
 * para a cuidadora consultar as opções de assinatura.
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
import '../../data/repositories/subscriptions_repository.dart';
import '../bloc/subscriptions_bloc.dart';
import '../widgets/subscriptions_content.dart';

/// Ponto de entrada da tela de assinaturas.
class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SubscriptionsBloc(repository: SubscriptionsRepository())
            ..add(const SubscriptionsLoadEvent()),
      child: const _SubscriptionsView(),
    );
  }
}

class _SubscriptionsView extends StatelessWidget {
  const _SubscriptionsView();

  void _onBottomNavTap(BuildContext context, int index) {
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

  void _showFeedback(BuildContext context, String message) {
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
          backgroundColor: AppColors.primaryDark,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: BlocConsumer<SubscriptionsBloc, SubscriptionsState>(
          listenWhen: (previous, current) =>
              previous.feedbackSequence != current.feedbackSequence,
          listener: (context, state) {
            final message = state.feedbackMessage;
            if (message != null) _showFeedback(context, message);
          },
          builder: (context, state) {
            return Column(
              children: [
                AppHeader(
                  photoUrl: state.caregiverPhotoUrl,
                  onSettingsPressed: () => context.go(AppRoutes.settings),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.splashGradient,
                    ),
                    child: _SubscriptionsBody(state: state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}

class _SubscriptionsBody extends StatelessWidget {
  const _SubscriptionsBody({required this.state});

  final SubscriptionsState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SubscriptionsStatus.initial:
      case SubscriptionsStatus.loading:
        return const AppLoading();
      case SubscriptionsStatus.failure:
        return AppErrorView(
          message: state.errorMessage ?? 'Não foi possível carregar os planos.',
          onRetry: () => context.read<SubscriptionsBloc>().add(
            const SubscriptionsLoadEvent(),
          ),
        );
      case SubscriptionsStatus.success:
        return SubscriptionsContent(
          plans: state.plans,
          currentPlanId: state.currentPlanId,
          billingCycle: state.billingCycle,
          annualDiscountPercent: state.annualDiscountPercent,
          contractedSubscription: state.contractedSubscription,
          onBillingCycleChanged: (cycle) => context
              .read<SubscriptionsBloc>()
              .add(SubscriptionsBillingCycleChangedEvent(cycle)),
          onPlanAction: (planId) => context.read<SubscriptionsBloc>().add(
            SubscriptionsPlanActionEvent(planId),
          ),
        );
    }
  }
}
