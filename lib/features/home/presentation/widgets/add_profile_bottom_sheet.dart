import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/care_recipient_type.dart';
import '../bloc/home_bloc.dart';

/// Bottom sheet for adding a new Care Recipient profile.
///
/// Called from [HomePage] when the user taps "Adicionar Perfil".
/// Dispatches [HomeAddProfileEvent] on confirmation.
class AddProfileBottomSheet extends StatefulWidget {
  const AddProfileBottomSheet({super.key});

  /// Shows the bottom sheet and returns when dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: const AddProfileBottomSheet(),
      ),
    );
  }

  @override
  State<AddProfileBottomSheet> createState() => _AddProfileBottomSheetState();
}

class _AddProfileBottomSheetState extends State<AddProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  CareRecipientType _selectedType = CareRecipientType.elderly;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<HomeBloc>().add(
          HomeAddProfileEvent(
            name: _nameController.text.trim(),
            recipientType: _selectedType,
            dateOfBirth: _dateOfBirth,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.addProfileSuccess != curr.addProfileSuccess ||
          prev.addProfileError != curr.addProfileError,
      listener: (context, state) {
        if (state.addProfileSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Perfil criado com sucesso!',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          );
        } else if (state.addProfileError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao criar perfil. Tente novamente.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.error,
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
            // Drag handle
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

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Criar Perfil',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Preencha os detalhes do perfil a ser cuidado.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar placeholder + button
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceVariant,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 44,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Name field
                      AppTextField(
                        controller: _nameController,
                        label: 'Nome Completo',
                        hint: 'Ex: Maria Oliveira',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o nome.';
                          }
                          if (value.trim().length < 2) {
                            return 'O nome deve ter pelo menos 2 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Date of birth
                      _DatePickerField(
                        selectedDate: _dateOfBirth,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Type selector label
                      Text(
                        'Quem será cuidado?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Type chips grid
                      _TypeChipSelector(
                        selected: _selectedType,
                        onSelected: (type) {
                          setState(() => _selectedType = type);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit button
                      BlocBuilder<HomeBloc, HomeState>(
                        buildWhen: (prev, curr) =>
                            prev.isAddingProfile != curr.isAddingProfile,
                        builder: (context, state) {
                          return AppButton(
                            label: 'Criar Perfil',
                            onPressed: state.isAddingProfile
                                ? null
                                : () => _submit(context),
                            isLoading: state.isAddingProfile,
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

// ---------------------------------------------------------------------------
// Date Picker Field
// ---------------------------------------------------------------------------

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onTap,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;

  String get _label {
    if (selectedDate == null) return 'dd/mm/aaaa';
    return '${selectedDate!.day.toString().padLeft(2, '0')}/'
        '${selectedDate!.month.toString().padLeft(2, '0')}/'
        '${selectedDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data de Nascimento',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Type Chip Selector
// ---------------------------------------------------------------------------

class _TypeChipSelector extends StatelessWidget {
  const _TypeChipSelector({
    required this.selected,
    required this.onSelected,
  });

  final CareRecipientType selected;
  final ValueChanged<CareRecipientType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: CareRecipientType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconFor(type),
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  type.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(CareRecipientType type) {
    return switch (type) {
      CareRecipientType.child => Icons.child_care_outlined,
      CareRecipientType.elderly => Icons.elderly_outlined,
      CareRecipientType.pet => Icons.pets_outlined,
      CareRecipientType.other => Icons.person_outline,
    };
  }
}
