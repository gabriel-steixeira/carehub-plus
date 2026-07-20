import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Enum for task categories.
enum TaskCategory {
  medication('Medicamento', 'medication', Icons.medication_outlined, AppColors.error),
  food('Alimentação', 'food', Icons.restaurant_outlined, AppColors.warning),
  appointment('Consulta', 'appointment', Icons.calendar_today_outlined, AppColors.info),
  activity('Atividade', 'activity', Icons.fitness_center_outlined, AppColors.primary),
  other('Outro', 'other', Icons.task_outlined, AppColors.textSecondary);

  const TaskCategory(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  static TaskCategory fromValue(String value) {
    return TaskCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskCategory.other,
    );
  }
}
