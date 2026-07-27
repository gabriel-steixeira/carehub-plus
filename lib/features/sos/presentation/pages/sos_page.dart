import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/sos_repository.dart';
import '../bloc/sos_bloc.dart';
import '../widgets/emergency_contact_tile.dart';
import '../widgets/protocol_card.dart';
import '../widgets/sos_button.dart';

/// Main SOS Emergency Page.
class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SosBloc(
        repository: SosRepository(),
      )..add(const SosLoadEvent()),
      child: const SosView(),
    );
  }
}

class SosView extends StatelessWidget {
  const SosView({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.push(AppRoutes.tasks);
        break;
      case 2:
        context.push(AppRoutes.coraChat);
        break;
      case 3:
        context.push(AppRoutes.chat);
        break;
      case 4:
        // Already on SOS
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'SOS & Emergências',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<SosBloc, SosState>(
          builder: (context, state) {
            if ((state.status == SosStatus.loading ||
                    state.status == SosStatus.initial) &&
                state.contacts.isEmpty) {
              return const AppLoading();
            }

            if (state.status == SosStatus.failure && state.contacts.isEmpty) {
              return AppErrorView(
                message:
                    state.errorMessage ?? 'Erro ao carregar o SOS de emergência.',
                onRetry: () {
                  context.read<SosBloc>().add(const SosLoadEvent());
                },
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // Panic SOS Button
                  SosButton(
                    isTriggered: state.alertTriggered,
                    onPressed: () {
                      if (state.alertTriggered) {
                        context.read<SosBloc>().add(const SosCancelAlertEvent());
                      } else {
                        context
                            .read<SosBloc>()
                            .add(const SosTriggerAlertEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🚨 ALERTA DISPARADO PARA A REDE DE APOIO!',
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Emergency Contacts Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Serviços e Contatos de Emergência',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  ...state.contacts.map((contact) {
                    return EmergencyContactTile(
                      contact: contact,
                      onCall: () async {
                        final cleanPhone =
                            contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
                        final Uri uri = Uri.parse('tel:$cleanPhone');
                        try {
                          await launchUrl(uri);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Iniciando chamada para ${contact.name} (${contact.phone})...',
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: Colors.white),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        }
                      },
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),

                  // First-Aid Protocols Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Instruções de Primeiros Socorros',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  ...state.protocols.map((protocol) {
                    return ProtocolCard(protocol: protocol);
                  }),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}
