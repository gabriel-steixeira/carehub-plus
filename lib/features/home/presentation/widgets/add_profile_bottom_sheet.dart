import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../services/image_upload_service.dart';
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
      // Sem constraints o modal cresce até a tela inteira conforme o
      // formulário aumenta. O conteúdo extra fica na rolagem interna.
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.85,
      ),
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
  final _imageUploadService = ImageUploadService();

  CareRecipientType _selectedType = CareRecipientType.elderly;
  DateTime? _dateOfBirth;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Escolher foto',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text('Galeria',
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSourceChoice.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text('Câmera',
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSourceChoice.camera),
              ),
              if (_selectedImage != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text('Remover foto',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.error)),
                  onTap: () => Navigator.pop(ctx, ImageSourceChoice.remove),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    if (source == ImageSourceChoice.remove) {
      setState(() => _selectedImage = null);
      return;
    }

    final file = source == ImageSourceChoice.gallery
        ? await _imageUploadService.pickImageFromGallery()
        : await _imageUploadService.pickImageFromCamera();

    if (file != null) {
      setState(() => _selectedImage = file);
    }
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
    // Verifica se o formulário é válido
    if (!_formKey.currentState!.validate()) return;
    
    // Obtém o estado atual do BLoC
    final homeBloc = context.read<HomeBloc>();
    final state = homeBloc.state;
    
    // Protege contra dupla submissão - se já está adicionando, não faz nada
    if (state.isAddingProfile) {
      return;
    }
    
    // Dispara o evento apenas se não está em processo de adição
    homeBloc.add(
      HomeAddProfileEvent(
        name: _nameController.text.trim(),
        recipientType: _selectedType,
        dateOfBirth: _dateOfBirth,
        imageFile: _selectedImage,
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
          // Fecha o bottom sheet
          Navigator.of(context).pop();
          
          // Aguarda um frame para o sheet fechar completamente antes de mostrar o SnackBar
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
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
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              );
            }
          });
        } else if (state.addProfileError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.addProfileError!,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                'Adicionar Novo Perfil',
                  textAlign: TextAlign.left,
                  style: AppTypography.averiaDisplayLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: context.scaleFont(24),
                  ),
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
                        child: GestureDetector(
                          onTap: _pickImage,
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
                                  image: _selectedImage != null
                                      ? DecorationImage(
                                          image: FileImage(_selectedImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _selectedImage == null
                                    ? const Icon(
                                        Icons.person_outline,
                                        size: 44,
                                        color: AppColors.primaryLight,
                                      )
                                    : null,
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

// ---------------------------------------------------------------------------
// Image Source Choice
// ---------------------------------------------------------------------------

/// Options for the image source picker bottom sheet.
enum ImageSourceChoice { gallery, camera, remove }
