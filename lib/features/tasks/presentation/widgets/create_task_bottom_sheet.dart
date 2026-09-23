import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_helper.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/date_picker_bottom_sheet.dart';
import '../../../categories/presentation/bloc/care_categories_bloc.dart';
import '../../../categories/presentation/models/category_visuals.dart';
import '../../../network/data/models/network_member_model.dart';
import '../../../network/presentation/bloc/network_bloc.dart';
import '../../data/models/task_frequency.dart';
import '../bloc/tasks_bloc.dart';

/// Modal Bottom Sheet to create a new task.
class CreateTaskBottomSheet extends StatefulWidget {
  const CreateTaskBottomSheet({super.key, required this.careRecipientId});

  final String careRecipientId;

  static Future<void> show(
    BuildContext context, {
    required String careRecipientId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TasksBloc>()),
          BlocProvider.value(value: context.read<CareCategoriesBloc>()),
          BlocProvider.value(value: context.read<NetworkBloc>()),
        ],
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

  String? _categoryId;
  TaskFrequency _frequency = TaskFrequency.daily;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  NetworkMemberModel? _selectedMember;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await DatePickerBottomSheet.show(
      context,
      initialDate: _selectedDate,
      minDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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

  void _submit(String fallbackCategoryId) {
    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _time.hour,
      _time.minute,
    );

    context.read<TasksBloc>().add(
      TaskCreateEvent(
        careRecipientId: widget.careRecipientId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        scheduledTime: scheduledDateTime,
        categoryId: _categoryId ?? fallbackCategoryId,
        frequency: _frequency,
        assignedToName: _selectedMember?.name,
        assignedToMemberId: _selectedMember?.id,
        assignedToPhotoUrl: _selectedMember?.photoUrl,
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

                      // Date and Time Picker Row
                      Row(
                        children: [
                          // Data
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            DateFormatHelper.formatHumanized(
                                              _selectedDate,
                                            ),
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                          // Horário
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
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
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
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Frequency
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
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TaskFrequency>(
                            value: _frequency,
                            isExpanded: true,
                            items: TaskFrequency.values.map((freq) {
                              return DropdownMenuItem(
                                value: freq,
                                child: Text(
                                  freq.label,
                                  style: AppTypography.bodyMedium,
                                ),
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
                      BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
                        builder: (context, categoriesState) {
                          final categories = categoriesState.categories;
                          if (categories.isEmpty) {
                            return const SizedBox(
                              height: 32,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          final effectiveId =
                              _categoryId ?? categories.first.id;

                          return Wrap(
                            spacing: AppSpacing.sm,
                            children: categories.map((category) {
                              final isSelected = effectiveId == category.id;
                              final color = colorForCategory(category);
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      iconForCategory(category),
                                      size: 14,
                                      color: isSelected ? Colors.white : color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(category.label),
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
                                  if (selected) {
                                    setState(() => _categoryId = category.id);
                                  }
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Responsible member
                      Text(
                        'Responsável (opcional)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MemberSelector(
                        careRecipientId: widget.careRecipientId,
                        selectedMember: _selectedMember,
                        onChanged: (member) =>
                            setState(() => _selectedMember = member),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      BlocBuilder<TasksBloc, TasksState>(
                        builder: (context, state) {
                          final categories = context
                              .watch<CareCategoriesBloc>()
                              .state
                              .categories;
                          final fallbackId = categories.isNotEmpty
                              ? categories.first.id
                              : 'other';
                          return AppButton(
                            label: 'Salvar Tarefa',
                            onPressed: state.isCreatingTask
                                ? null
                                : () => _submit(fallbackId),
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

class _MemberSelector extends StatelessWidget {
  const _MemberSelector({
    required this.careRecipientId,
    required this.selectedMember,
    required this.onChanged,
  });

  final String careRecipientId;
  final NetworkMemberModel? selectedMember;
  final ValueChanged<NetworkMemberModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    final allMembers = context.watch<NetworkBloc>().state.members;
    final members = allMembers
        .where(
          (member) =>
              member.careRecipientId == null ||
              member.careRecipientId == careRecipientId,
        )
        .toList();
    final effectiveMember = members.contains(selectedMember)
        ? selectedMember
        : null;

    if (members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          'Nenhum membro cadastrado para este perfil.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<NetworkMemberModel>(
          value: effectiveMember,
          hint: Text(
            'Eu / sem responsável',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          items: members
              .map(
                (member) => DropdownMenuItem<NetworkMemberModel>(
                  value: member,
                  child: Row(
                    children: [
                      AppMemberAvatar(
                        photo: member.photoUrl,
                        diameter: AppSpacing.xl,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          member.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
