/*
 * CareHub Plus — Perfil / Campo de Gênero
 *
 * Seleção de gênero em dropdown. É uma escolha neutra (não muda permissões nem
 * o que a pessoa pode fazer no app), então o dropdown é adequado — cartões
 * explicativos ficam reservados para escolhas com consequência.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/caregiver_gender.dart';
import 'profile_labeled_field.dart';

/// Campo de seleção de gênero do cuidador.
class ProfileGenderField extends StatelessWidget {
  const ProfileGenderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Rótulo em caixa alta (ex.: "GÊNERO").
  final String label;

  /// Gênero selecionado. `null` mostra a dica de seleção.
  final CaregiverGender? value;

  /// Chamado quando uma opção é escolhida.
  final ValueChanged<CaregiverGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileLabeledField(
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CaregiverGender>(
          value: value,
          isExpanded: true,
          hint: Text(
            'Selecione',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textHint),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          items: CaregiverGender.values.map((gender) {
            return DropdownMenuItem<CaregiverGender>(
              value: gender,
              child: Text(
                gender.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (gender) {
            if (gender != null) onChanged(gender);
          },
        ),
      ),
    );
  }
}
