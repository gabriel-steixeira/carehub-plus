/*
 * CareHub Plus — Apresentação / Navegação de Data das Tarefas
 *
 * Barra "< Hoje 30-04-2026 >" para navegar entre os dias. Extraída de
 * `tasks_page.dart` para manter a página como composição.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Navegação de dia anterior/próximo com o rótulo da data selecionada.
class TasksDateNavigationBar extends StatelessWidget {
  const TasksDateNavigationBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  static const List<String> _weekdayLabels = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateTitle(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hoje';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Ontem';
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Amanhã';
    return _weekdayLabels[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          tooltip: 'Dia anterior',
          onPressed: () => onDateChanged(
            selectedDate.subtract(const Duration(days: 1)),
          ),
        ),
        Column(
          children: [
            Text(
              _dateTitle(selectedDate),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDate(selectedDate),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          tooltip: 'Próximo dia',
          onPressed: () => onDateChanged(
            selectedDate.add(const Duration(days: 1)),
          ),
        ),
      ],
    );
  }
}
