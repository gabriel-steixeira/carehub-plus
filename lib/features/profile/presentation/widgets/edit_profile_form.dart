/*
 * CareHub Plus — Perfil / Formulário de Edição
 *
 * Reúne os campos cadastrais do cuidador, os atalhos de privacidade e plano e o
 * botão Salvar. Guarda apenas estado de interface (texto digitado, data e gênero
 * escolhidos) e valida formato; quem grava é o `EditProfileBloc`.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/caregiver_gender.dart';
import '../../domain/entities/caregiver_profile_entity.dart';
import '../../../subscriptions/domain/entities/contracted_subscription_entity.dart';
import '../../../subscriptions/domain/entities/subscription_plan_entity.dart';
import '../bloc/edit_profile_bloc.dart';
import 'data_privacy_card.dart';
import 'family_plan_card.dart';
import 'profile_birth_date_field.dart';
import 'profile_gender_field.dart';
import 'profile_photo_picker.dart';

/// Formulário de edição do perfil do cuidador.
class EditProfileForm extends StatefulWidget {
  const EditProfileForm({
    super.key,
    required this.profile,
    required this.plan,
    required this.contractedSubscription,
    required this.onPrivacyTap,
    required this.onChangePlan,
  });

  /// Perfil carregado, usado para preencher os campos na abertura.
  final CaregiverProfileEntity profile;

  /// Plano da conta, exibido no cartão do rodapé.
  final SubscriptionPlanEntity? plan;
  final ContractedSubscriptionEntity? contractedSubscription;

  /// Ação do cartão de privacidade.
  final VoidCallback onPrivacyTap;

  /// Ação de trocar de plano.
  final VoidCallback onChangePlan;

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _imageUploadService = ImageUploadService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  DateTime? _birthDate;
  CaregiverGender? _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _birthDate = widget.profile.birthDate;
    _gender = widget.profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<_PhotoSourceChoice>(
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
                'Trocar foto do perfil',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Galeria',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, _PhotoSourceChoice.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Câmera',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, _PhotoSourceChoice.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    File? file;
    if (source == _PhotoSourceChoice.gallery) {
      file = await _imageUploadService.pickImageFromGallery();
    } else {
      file = await _imageUploadService.pickImageFromCamera();
    }

    if (file != null && mounted) {
      context.read<EditProfileBloc>().add(
        EditProfilePhotoChangedEvent(imageFile: file),
      );
    }
  }

  /// Rótulos em caixa alta, no mesmo estilo em todos os campos.
  TextStyle get _labelStyle =>
      AppTypography.sectionLabel.copyWith(color: AppColors.textSecondary);

  void _submit() {
    // `validate` já exibe as mensagens sob cada campo.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    final currentProfile = context.read<EditProfileBloc>().state.profile;

    context.read<EditProfileBloc>().add(
      EditProfileSubmitEvent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        birthDate: _birthDate,
        gender: _gender,
        photoBase64: currentProfile?.photoBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child:
                BlocSelector<
                  EditProfileBloc,
                  EditProfileState,
                  CaregiverProfileEntity?
                >(
                  selector: (state) => state.profile,
                  builder: (context, profile) {
                    return ProfilePhotoPicker(
                      photoUrl: profile?.photoUrl,
                      photoBase64: profile?.photoBase64,
                      onTap: _pickPhoto,
                    );
                  },
                ),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            controller: _nameController,
            label: 'NOME COMPLETO',
            labelStyle: _labelStyle,
            hint: 'Como você quer ser chamada',
            // Os campos ficam sobre o gradiente da página, então precisam de
            // fundo próprio — os mesmos widgets do login, com o preenchimento
            // ligado.
            filled: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (value) => Validators.required(value, 'nome completo'),
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            controller: _emailController,
            label: 'E-MAIL',
            labelStyle: _labelStyle,
            hint: 'seu@email.com',
            filled: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            controller: _phoneController,
            label: 'TELEFONE',
            labelStyle: _labelStyle,
            hint: '(11) 98765-4321',
            filled: true,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: Validators.optionalPhone,
          ),
          const SizedBox(height: AppSpacing.md),

          // Nascimento e gênero dividem a linha, como no Figma. Os dois campos
          // têm a mesma altura por `ProfileLabeledField.fieldHeight`.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProfileBirthDateField(
                  label: 'NASCIMENTO',
                  value: _birthDate,
                  onChanged: (date) => setState(() => _birthDate = date),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ProfileGenderField(
                  label: 'GÊNERO',
                  value: _gender,
                  onChanged: (gender) => setState(() => _gender = gender),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          DataPrivacyCard(onTap: widget.onPrivacyTap),
          const SizedBox(height: AppSpacing.md),

          FamilyPlanCard(
            plan: widget.plan,
            subscription: widget.contractedSubscription,
            onChangePlan: widget.onChangePlan,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Só o botão reconstrói durante a gravação — o formulário inteiro não
          // precisa ser refeito para mostrar o carregamento.
          BlocBuilder<EditProfileBloc, EditProfileState>(
            buildWhen: (previous, current) =>
                previous.isSaving != current.isSaving,
            builder: (context, state) {
              return AppButton(
                label: 'Salvar',
                onPressed: state.isSaving ? null : _submit,
                isLoading: state.isSaving,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo Source Choice
// ---------------------------------------------------------------------------

enum _PhotoSourceChoice { gallery, camera }
