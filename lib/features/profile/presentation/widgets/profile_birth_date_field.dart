/*
 * CareHub Plus — Perfil / Campo de Data de Nascimento
 *
 * Campo somente leitura que abre o calendário do sistema. Escolher no
 * calendário evita máscara de digitação e datas impossíveis, e o texto exibido
 * segue o formato brasileiro (dd/mm/aaaa).
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'profile_labeled_field.dart';

/// Campo de data de nascimento do cuidador.
class ProfileBirthDateField extends StatelessWidget {
  const ProfileBirthDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Rótulo em caixa alta (ex.: "NASCIMENTO").
  final String label;

  /// Data selecionada. `null` mostra o formato esperado como dica.
  final DateTime? value;

  /// Chamado quando uma data é confirmada no calendário.
  final ValueChanged<DateTime> onChanged;

  /// Idade inicial sugerida no calendário quando ainda não há data — evita
  /// abrir em 1900 e obrigar a rolar décadas.
  static const int _suggestedAge = 30;

  /// Idade máxima aceita, usada como limite inferior do calendário.
  static const int _maxAge = 120;

  String get _text {
    final date = value;
    if (date == null) return 'dd/mm/aaaa';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(today.year - _suggestedAge),
      firstDate: DateTime(today.year - _maxAge),
      // Ninguém nasce no futuro.
      lastDate: today,
      helpText: 'Selecione sua data de nascimento',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );

    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return ProfileLabeledField(
      label: label,
      onTap: () => _pickDate(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge.copyWith(
                color: hasValue ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
