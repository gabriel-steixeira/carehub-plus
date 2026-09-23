/*
 * CareHub Plus — Shared Widget / Date Picker Bottom Sheet
 *
 * Modal bottom sheet com calendário interativo para seleção de datas.
 * Inclui atalhos rápidos (Hoje, Amanhã, +3 dias) e navegação mensal.
 * Usado em tarefas, lembretes e qualquer feature que precise de agendamento.
 *
 * Author: Vitoria Lana
 * Created on: 23/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Modal Bottom Sheet para seleção de data com calendário interativo.
///
/// Características:
/// - Atalhos rápidos: Hoje, Amanhã, +3 dias, +7 dias
/// - Navegação entre meses com setas
/// - Visualização de calendário mensal
/// - Data inicial personalizável
/// - Responsivo e acessível
class DatePickerBottomSheet extends StatefulWidget {
  const DatePickerBottomSheet({
    super.key,
    required this.initialDate,
    this.minDate,
    this.maxDate,
  });

  /// Data inicialmente selecionada
  final DateTime initialDate;

  /// Data mínima selecionável (opcional)
  final DateTime? minDate;

  /// Data máxima selecionável (opcional)
  final DateTime? maxDate;

  /// Exibe o bottom sheet e retorna a data selecionada, ou null se cancelado.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DatePickerBottomSheet(
        initialDate: initialDate,
        minDate: minDate,
        maxDate: maxDate,
      ),
    );
  }

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('pt_BR', null);
    if (mounted) {
      setState(() => _localeInitialized = true);
    }
  }

  bool _isDateSelectable(DateTime date) {
    if (widget.minDate != null &&
        date.isBefore(
          DateTime(
            widget.minDate!.year,
            widget.minDate!.month,
            widget.minDate!.day,
          ),
        )) {
      return false;
    }
    if (widget.maxDate != null &&
        date.isAfter(
          DateTime(
            widget.maxDate!.year,
            widget.maxDate!.month,
            widget.maxDate!.day,
          ),
        )) {
      return false;
    }
    return true;
  }

  void _onDateSelected(DateTime date) {
    if (_isDateSelectable(date)) {
      setState(() => _selectedDate = date);
    }
  }

  void _onMonthChanged(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
    });
  }

  void _onShortcutSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Aguarda inicialização do locale
    if (!_localeInitialized) {
      return Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXl),
            topRight: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Selecione a Data',
              style: AppTypography.averiaDisplayLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // Atalhos rápidos
                  _QuickShortcuts(
                    selectedDate: _selectedDate,
                    onShortcutSelected: _onShortcutSelected,
                    isDateSelectable: _isDateSelectable,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Navegação de mês/ano
                  _MonthNavigation(
                    displayedMonth: _displayedMonth,
                    onMonthChanged: _onMonthChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Calendário
                  _CalendarGrid(
                    displayedMonth: _displayedMonth,
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                    isDateSelectable: _isDateSelectable,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Botão confirmar
                  AppButton(
                    label: 'Confirmar',
                    onPressed: _confirm,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalhos rápidos para datas comuns
class _QuickShortcuts extends StatelessWidget {
  const _QuickShortcuts({
    required this.selectedDate,
    required this.onShortcutSelected,
    required this.isDateSelectable,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onShortcutSelected;
  final bool Function(DateTime) isDateSelectable;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final plus3 = today.add(const Duration(days: 3));
    final plus7 = today.add(const Duration(days: 7));

    final shortcuts = [
      ('Hoje', today),
      ('Amanhã', tomorrow),
      ('+3 dias', plus3),
      ('+7 dias', plus7),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: shortcuts.map((shortcut) {
        final label = shortcut.$1;
        final date = shortcut.$2;
        final isSelected = _isSameDay(date, selectedDate);
        final isEnabled = isDateSelectable(date);

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: isEnabled ? (_) => onShortcutSelected(date) : null,
          selectedColor: AppColors.primary,
          labelStyle: AppTypography.labelLarge.copyWith(
            color: isSelected
                ? Colors.white
                : isEnabled
                    ? AppColors.textPrimary
                    : AppColors.textHint,
          ),
          disabledColor: AppColors.surfaceVariant,
        );
      }).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Navegação entre meses
class _MonthNavigation extends StatelessWidget {
  const _MonthNavigation({
    required this.displayedMonth,
    required this.onMonthChanged,
  });

  final DateTime displayedMonth;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(displayedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onMonthChanged(-1),
          color: AppColors.primary,
        ),
        Text(
          monthName,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onMonthChanged(1),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

/// Grid de calendário mensal
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.displayedMonth,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isDateSelectable,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool Function(DateTime) isDateSelectable;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month);
    final lastDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    );

    // Dias da semana (D S T Q Q S S)
    final weekDays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    // Calcular offset do primeiro dia (domingo = 0)
    final firstWeekday = firstDayOfMonth.weekday % 7;

    // Lista de todos os dias do mês
    final daysInMonth = <DateTime?>[];

    // Adicionar espaços vazios antes do primeiro dia
    for (var i = 0; i < firstWeekday; i++) {
      daysInMonth.add(null);
    }

    // Adicionar todos os dias do mês
    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      daysInMonth.add(DateTime(displayedMonth.year, displayedMonth.month, day));
    }

    return Column(
      children: [
        // Cabeçalho com dias da semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map(
                (day) => SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      day,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Grid de dias
        Wrap(
          children: daysInMonth.map((date) {
            if (date == null) {
              return const SizedBox(width: 40, height: 40);
            }

            final isSelected = _isSameDay(date, selectedDate);
            final isToday = _isSameDay(date, DateTime.now());
            final isSelectable = isDateSelectable(date);

            return GestureDetector(
              onTap: isSelectable ? () => onDateSelected(date) : null,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : isSelectable
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                      fontWeight:
                          isToday || isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
