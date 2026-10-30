/*
 * CareHub Plus — Widget Compartilhado / Dropdown em Caixa com Borda
 *
 * Caixa com borda arredondada envolvendo um DropdownButton sem underline, no
 * estilo padrão de campo de seleção do app (frequência de tarefa, responsável,
 * função na rede). Fonte única dessa aparência. Não cobre o campo de gênero do
 * perfil, que usa a caixa preenchida de altura fixa do ProfileLabeledField.
 *
 * Author: Vitoria Lana
 * Created on: 16/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Dropdown no estilo de campo com borda do app.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.isExpanded = true,
  });

  /// Valor selecionado (ou `null`).
  final T? value;

  /// Itens do dropdown.
  final List<DropdownMenuItem<T>> items;

  /// Disparado na seleção (pode receber `null`).
  final ValueChanged<T?>? onChanged;

  /// Dica exibida quando [value] é `null`.
  final Widget? hint;

  /// Se o botão ocupa toda a largura. Padrão `true`.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hint,
          isExpanded: isExpanded,
        ),
      ),
    );
  }
}
