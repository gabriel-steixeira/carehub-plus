/*
 * CareHub Plus — Convites / Opções de acesso do membro
 *
 * As três escolhas do cadastro da rede de apoio que valem para o acesso
 * compartilhado: por quanto tempo vale, por onde chegam os alertas (SOS e
 * tarefa atribuída) e por onde vai o convite. Escolhas com consequência são
 * cartões explicados, como manda o design system. Só desenha e avisa: quem
 * guarda o estado é o formulário que o usa.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_form_label.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../network/data/models/network_member_model.dart';
import '../../domain/entities/invite_channel.dart';

/// Prazos prontos; "Outro" libera um número de horas livre.
enum AccessDurationOption {
  oneDay('24 horas', 24),
  threeDays('3 dias', 72),
  sevenDays('7 dias', 168),
  thirtyDays('30 dias', 720),
  unlimited('Ilimitado', null),
  custom('Outro', null);

  const AccessDurationOption(this.label, this.hours);
  final String label;

  /// Horas do prazo; `null` em [unlimited] e [custom].
  final int? hours;

  static AccessDurationOption fromHours(int? hours) {
    if (hours == null) return AccessDurationOption.unlimited;
    return AccessDurationOption.values.firstWhere(
      (option) => option.hours == hours,
      orElse: () => AccessDurationOption.custom,
    );
  }
}

/// Canais de alerta como a dona escolhe (cada opção explica o efeito).
enum AlertDelivery {
  both(
    'WhatsApp e app',
    'Recebe os alertas de SOS e de tarefa nos dois lugares.',
    [AlertChannel.whatsapp, AlertChannel.app],
  ),
  whatsapp(
    'Só WhatsApp',
    'Ideal para quem não usa o app. Vale para qualquer nível de acesso.',
    [AlertChannel.whatsapp],
  ),
  app(
    'Só app',
    'Recebe no sino e no celular, pelo app. Não recebe WhatsApp.',
    [AlertChannel.app],
  );

  const AlertDelivery(this.label, this.description, this.channels);
  final String label;
  final String description;
  final List<AlertChannel> channels;

  static AlertDelivery fromChannels(List<AlertChannel> channels) {
    final hasWhatsApp = channels.contains(AlertChannel.whatsapp);
    final hasApp = channels.contains(AlertChannel.app);
    if (hasWhatsApp && !hasApp) return AlertDelivery.whatsapp;
    if (hasApp && !hasWhatsApp) return AlertDelivery.app;
    return AlertDelivery.both;
  }
}

/// Seções de prazo, alertas e convite do formulário do membro.
class MemberAccessOptions extends StatefulWidget {
  const MemberAccessOptions({
    super.key,
    required this.durationHours,
    required this.onDurationChanged,
    required this.alertDelivery,
    required this.onAlertDeliveryChanged,
    required this.inviteChannel,
    required this.onInviteChannelChanged,
    required this.isReadonly,
    required this.allowNoInvite,
    this.showAppAlertNotice = false,
    this.durationError,
  });

  /// `null` = ilimitado; `0` = prazo livre ainda inválido.
  final int? durationHours;
  final ValueChanged<int?> onDurationChanged;

  final AlertDelivery alertDelivery;
  final ValueChanged<AlertDelivery> onAlertDeliveryChanged;

  /// `null` = não enviar convite agora.
  final InviteChannel? inviteChannel;
  final ValueChanged<InviteChannel?> onInviteChannelChanged;

  /// "Apenas Visualização" não inclui WhatsApp no convite.
  final bool isReadonly;

  /// Na edição dá para salvar sem mandar um novo convite.
  final bool allowNoInvite;

  /// A pessoa ainda não aceitou: o alerta pelo app só chega depois.
  final bool showAppAlertNotice;

  /// Erro do prazo livre (ex.: vazio ou zero).
  final String? durationError;

  @override
  State<MemberAccessOptions> createState() => _MemberAccessOptionsState();
}

class _MemberAccessOptionsState extends State<MemberAccessOptions> {
  late AccessDurationOption _durationOption;
  late final TextEditingController _customHoursController;

  @override
  void initState() {
    super.initState();
    _durationOption = AccessDurationOption.fromHours(widget.durationHours);
    _customHoursController = TextEditingController(
      text: _durationOption == AccessDurationOption.custom
          ? '${widget.durationHours}'
          : '',
    );
  }

  @override
  void dispose() {
    _customHoursController.dispose();
    super.dispose();
  }

  void _selectDuration(AccessDurationOption option) {
    setState(() => _durationOption = option);
    widget.onDurationChanged(
      option == AccessDurationOption.custom
          ? _customHours(_customHoursController.text)
          : option.hours,
    );
  }

  /// Prazo livre inválido vira 0 (e não `null`, que significa ilimitado),
  /// para o formulário conseguir mostrar o erro.
  int _customHours(String text) {
    final hours = int.tryParse(text.trim());
    return hours == null || hours <= 0 ? 0 : hours;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Prazo de acesso ───────────────────────────────────────────
        const AppFormLabel('Prazo de acesso', spacing: AppSpacing.xs),
        Text(
          'Conta a partir de quando a pessoa aceita o convite. Você pode '
          'remover o acesso a qualquer momento.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in AccessDurationOption.values)
              ChoiceChip(
                label: Text(option.label),
                selected: option == _durationOption,
                onSelected: (_) => _selectDuration(option),
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: option == _durationOption
                      ? AppColors.textInverse
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                showCheckmark: false,
                side: BorderSide(
                  color: option == _durationOption
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
          ],
        ),
        if (_durationOption == AccessDurationOption.custom) ...[
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _customHoursController,
            label: 'Quantas horas?',
            hint: 'Ex.: 12',
            prefixIcon: Icons.schedule_outlined,
            keyboardType: TextInputType.number,
            onChanged: (value) => widget.onDurationChanged(_customHours(value)),
          ),
        ],
        if (widget.durationError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.durationError!,
            style: AppTypography.labelSmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),

        // ── Canal de alertas ──────────────────────────────────────────
        const AppFormLabel('Como recebe os alertas'),
        for (final delivery in AlertDelivery.values) ...[
          _OptionCard(
            icon: switch (delivery) {
              AlertDelivery.both => Icons.notifications_active_outlined,
              AlertDelivery.whatsapp => Icons.chat_outlined,
              AlertDelivery.app => Icons.phone_iphone_rounded,
            },
            title: delivery.label,
            description: delivery.description,
            isSelected: delivery == widget.alertDelivery,
            onTap: () => widget.onAlertDeliveryChanged(delivery),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.showAppAlertNotice &&
            widget.alertDelivery.channels.contains(AlertChannel.app))
          _Notice(
            text:
                'O alerta pelo app só chega depois que a pessoa criar a conta '
                'e aceitar o convite.',
          ),
        const SizedBox(height: AppSpacing.md),

        // ── Canal do convite ──────────────────────────────────────────
        const AppFormLabel('Como enviar o convite'),
        if (widget.allowNoInvite) ...[
          _OptionCard(
            icon: Icons.do_not_disturb_on_outlined,
            title: 'Não enviar agora',
            description: 'Salva as alterações sem mandar um convite novo.',
            isSelected: widget.inviteChannel == null,
            onTap: () => widget.onInviteChannelChanged(null),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final channel in InviteChannel.values) ...[
          _OptionCard(
            icon: channel == InviteChannel.whatsapp
                ? Icons.chat_outlined
                : Icons.vpn_key_outlined,
            title: channel.label,
            description: channel.description,
            isSelected: channel == widget.inviteChannel,
            enabled: !(widget.isReadonly && channel == InviteChannel.whatsapp),
            onTap: () => widget.onInviteChannelChanged(channel),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.isReadonly)
          _Notice(
            text:
                'O nível Apenas Visualização não inclui o WhatsApp: a pessoa '
                'acompanha só pelo app. Os alertas acima continuam valendo.',
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão selecionável com ícone, título e explicação.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.textPrimary : AppColors.textHint;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $description',
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.smMd),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? AppColors.primary : AppColors.textHint,
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: AppColors.primary,
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
