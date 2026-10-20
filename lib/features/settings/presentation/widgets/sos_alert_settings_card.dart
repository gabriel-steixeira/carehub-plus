/*
 * CareHub Plus — Configurações / Cartão "Alertas de SOS"
 *
 * Seção da tela de Configurações onde o dono do perfil informa o telefone de
 * WhatsApp e escolhe o canal de alerta de SOS. O app sempre avisa o dono; o
 * WhatsApp é opcional. Widget de apresentação: recebe o estado e reporta
 * intenções ao SettingsBloc, sem lógica de negócio nem acesso a Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 19/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../network/data/models/network_member_model.dart';
import '../bloc/settings_bloc.dart';
import 'setting_toggle_tile.dart';

/// Cartão de preferências de alerta de SOS do dono do perfil.
class SosAlertSettingsCard extends StatefulWidget {
  const SosAlertSettingsCard({super.key, required this.state});

  final SettingsState state;

  @override
  State<SosAlertSettingsCard> createState() => _SosAlertSettingsCardState();
}

class _SosAlertSettingsCardState extends State<SosAlertSettingsCard> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.state.sosPhone);
  }

  @override
  void didUpdateWidget(covariant SosAlertSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mantém o campo em sincronia quando o estado muda por fora (ex.: recarga),
    // preservando o cursor quando o texto já é o mesmo que o usuário digitou.
    if (widget.state.sosPhone != _phoneController.text) {
      _phoneController.text = widget.state.sosPhone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final state = widget.state;
    final usesWhatsApp = state.sosAlertChannel == AlertChannel.whatsapp;
    final isSaving = state.sosSaveStatus == SettingsSosSaveStatus.saving;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sos_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Alertas de SOS',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Você sempre é avisada pelo app. Ative o WhatsApp para receber '
            'também por lá e informe seu número.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingToggleTile(
            title: 'Receber também por WhatsApp',
            subtitle: 'O app continua avisando mesmo com o WhatsApp desligado.',
            icon: Icons.chat_rounded,
            value: usesWhatsApp,
            onChanged: isSaving
                ? (_) {}
                : (value) => bloc.add(
                      SettingsSosChannelChangedEvent(
                        channel:
                            value ? AlertChannel.whatsapp : AlertChannel.app,
                      ),
                    ),
          ),
          if (usesWhatsApp) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Seu número de WhatsApp',
              hint: '(11) 99999-0000',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              enabled: !isSaving,
              onChanged: (value) =>
                  bloc.add(SettingsSosPhoneChangedEvent(phone: value)),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Salvar alertas de SOS',
            isLoading: isSaving,
            onPressed: isSaving
                ? null
                : () => bloc.add(const SettingsSaveSosPreferencesEvent()),
          ),
        ],
      ),
    );
  }
}
