/*
 * CareHub Plus — Convites / Tela "Tenho um convite"
 *
 * Onde a pessoa convidada digita ou cola o código recebido. Só composição:
 * cabeçalho, corpo conforme o `RedeemInviteBloc` (formulário, enviando,
 * erro e sucesso) e navegação inferior.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../data/repositories/invites_repository.dart';
import '../bloc/redeem_invite_bloc.dart';
import '../widgets/redeem_invite_form.dart';
import '../widgets/redeem_invite_success_view.dart';

/// Tela para aceitar um convite pelo código.
class RedeemInvitePage extends StatelessWidget {
  const RedeemInvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RedeemInviteBloc(repository: InvitesRepository()),
      child: const RedeemInviteView(),
    );
  }
}

class RedeemInviteView extends StatelessWidget {
  const RedeemInviteView({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            AppHeader(
              leading: AppBackButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: SizedBox.expand(
                  child: BlocBuilder<RedeemInviteBloc, RedeemInviteState>(
                    builder: (context, state) => AppResponsiveBody(
                      child: state.status == RedeemInviteStatus.success &&
                              state.redeemed != null
                          ? RedeemInviteSuccessView(
                              redeemed: state.redeemed!,
                              onGoHome: () => context.go(AppRoutes.home),
                              onUseAnother: () => context
                                  .read<RedeemInviteBloc>()
                                  .add(const RedeemInviteResetEvent()),
                            )
                          : RedeemInviteForm(
                              isSubmitting: state.isSubmitting,
                              errorMessage: state.errorMessage,
                              onSubmit: (code) =>
                                  context.read<RedeemInviteBloc>().add(
                                    RedeemInviteSubmittedEvent(code: code),
                                  ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: -1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}
