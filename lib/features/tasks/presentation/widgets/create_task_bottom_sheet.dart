import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/task_category.dart';
import '../../data/models/task_frequency.dart';
import '../bloc/tasks_bloc.dart';

/// Modal Bottom Sheet to create a new task.
class CreateTaskBottomSheet extends StatefulWidget {
  const CreateTaskBottomSheet({super.key, required this.careRecipientId});

  final String careRecipientId;

  static Future<void> show(BuildContext context, {required String careRecipientId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: CreateTaskBottomSheet(careRecipientId: careRecipientId),
      ),
    );
  }

  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assignedController = TextEditingController();

  TaskCategory _category = TaskCategory.medication;
  TaskFrequency _frequency = TaskFrequency.daily;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _assignedController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    context.read<TasksBloc>().add(
          TaskCreateEvent(
            careRecipientId: widget.careRecipientId,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            scheduledTime: scheduledDateTime,
            category: _category,
            frequency: _frequency,
            assignedToName: _assignedController.text.trim().isEmpty
                ? null
                : _assignedController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<TasksBloc, TasksState>(
      listenWhen: (prev, curr) =>
          prev.createTaskSuccess != curr.createTaskSuccess,
      listener: (context, state) {
        if (state.createTaskSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tarefa criada com sucesso!',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          );
        }
      },
      child: Container(
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
                'Nova Tarefa de Cuidado',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      AppTextField(
                        controller: _titleController,
                        label: 'Título da Tarefa',
                        hint: 'Ex: Dar medicação da pressão',
                        prefixIcon: Icons.assignment_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o título.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      AppTextField(
                        controller: _descController,
                        label: 'Instruções / Detalhes',
                        hint: 'Ex: 1 comprimido de Losartana após o café',
                        prefixIcon: Icons.notes_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Time Picker Field
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Horário',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                GestureDetector(
                                  onTap: _pickTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            color: AppColors.primary, size: 20),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Frequência',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<TaskFrequency>(
                                      value: _frequency,
                                      isExpanded: true,
                                      items: TaskFrequency.values.map((freq) {
                                        return DropdownMenuItem(
                                          value: freq,
                                          child: Text(freq.label,
                                              style: AppTypography.bodyMedium),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _frequency = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category Selector
                      Text(
                        'Categoria',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: TaskCategory.values.map((cat) {
                          final isSelected = _category == cat;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : cat.color,
                                ),
                                const SizedBox(width: 4),
                                Text(cat.label),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: AppTypography.labelSmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _category = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Assigned To Name
                      AppTextField(
                        controller: _assignedController,
                        label: 'Atribuir a (opcional)',
                        hint: 'Ex: Patrícia (Cuidadora)',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      BlocBuilder<TasksBloc, TasksState>(
                        builder: (context, state) {
                          return AppButton(
                            label: 'Salvar Tarefa',
                            onPressed: state.isCreatingTask ? null : _submit,
                            isLoading: state.isCreatingTask,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
