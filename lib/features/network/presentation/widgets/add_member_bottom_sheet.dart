import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../../shared/widgets/app_scroll_fade.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../services/image_upload_service.dart';
import '../../data/models/network_member_model.dart';
import '../bloc/network_bloc.dart';
import 'access_level_selector.dart';

/// Modal to invite a new member or edit an existing support network member.
class AddMemberBottomSheet extends StatefulWidget {
  const AddMemberBottomSheet({super.key, this.member, this.careRecipientId});

  final NetworkMemberModel? member;
  final String? careRecipientId;

  /// Fração da altura da tela que o modal pode ocupar. Sobra um pedaço do
  /// fundo à vista, deixando claro que é um modal e não uma página.
  static const double _maxHeightFactor = 0.85;

  static Future<void> show(
    BuildContext context, {
    NetworkMemberModel? member,
    String? careRecipientId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Sem esse limite o modal cresce até a tela inteira conforme o
      // formulário aumenta. Com ele, o conteúdo extra fica acessível na
      // rolagem interna.
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * _maxHeightFactor,
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<NetworkBloc>(),
        child: AddMemberBottomSheet(
          member: member,
          careRecipientId: careRecipientId,
        ),
      ),
    );
  }

  @override
  State<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends State<AddMemberBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _emailController = TextEditingController();
  final _imageUploadService = ImageUploadService();

  File? _selectedImage;
  bool _removePhoto = false;

  NetworkRole _role = NetworkRole.caregiver;
  AccessLevel _accessLevel = AccessLevel.full;

  /// Permissões marcadas para o "Acesso Parcial".
  final Set<NetworkPermission> _permissions = <NetworkPermission>{};

  /// Erro exibido quando o "Acesso Parcial" é salvo sem nenhuma permissão.
  String? _permissionError;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member == null) return;

    _nameController.text = member.name;
    _phoneController.text = member.phone;
    _relationshipController.text = member.relationship ?? '';
    _emailController.text = member.email ?? '';
    _role = member.role;
    _accessLevel = member.accessLevel;
    _permissions.addAll(member.permissions);
  }

  /// Troca o nível selecionado. Sair do "Acesso Parcial" limpa as permissões,
  /// que não fazem sentido nos outros níveis.
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<_ImageSourceChoice>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => SafeArea(
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
                onTap: () => Navigator.pop(context, _ImageSourceChoice.gallery),
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
                onTap: () => Navigator.pop(context, _ImageSourceChoice.camera),
              ),
              if (_selectedImage != null ||
                  (widget.member?.photoUrl != null && !_removePhoto))
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Remover foto',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () =>
                      Navigator.pop(context, _ImageSourceChoice.remove),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    if (source == _ImageSourceChoice.remove) {
      setState(() {
        _selectedImage = null;
        _removePhoto = true;
      });
      return;
    }

    final file = source == _ImageSourceChoice.gallery
        ? await _imageUploadService.pickImageFromGallery()
        : await _imageUploadService.pickImageFromCamera();
    if (file == null) return;

    setState(() {
      _selectedImage = file;
      _removePhoto = false;
    });
  }

  Widget _buildPhotoPicker() {
    final existingPhoto = _removePhoto ? null : widget.member?.photoUrl;
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.border,
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : AppMemberAvatar(photo: existingPhoto, diameter: 84),
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
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Troca o nível selecionado. Sair do "Acesso Parcial" limpa as permissões,
  /// que não fazem sentido nos outros níveis.
  void _onAccessLevelChanged(AccessLevel level) {
    setState(() {
      _accessLevel = level;
      if (level != AccessLevel.partial) {
        _permissions.clear();
        _permissionError = null;
      }
    });
  }

  void _onPermissionToggled(NetworkPermission permission) {
    setState(() {
      if (!_permissions.remove(permission)) _permissions.add(permission);
      if (_permissions.isNotEmpty) _permissionError = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    // "Acesso Parcial" sem nenhuma permissão marcada não dá acesso a nada.
    final isMissingPermissions =
        _accessLevel == AccessLevel.partial && _permissions.isEmpty;
    setState(() {
      _permissionError = isMissingPermissions
          ? 'Selecione ao menos uma permissão.'
          : null;
    });

    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid || isMissingPermissions) return;

    final relationship = _relationshipController.text.trim();
    final email = _emailController.text.trim();

    if (_isEditing) {
      final member = widget.member!;
      context.read<NetworkBloc>().add(
        NetworkUpdateMemberEvent(
          memberId: member.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _role,
          relationship: relationship.isEmpty ? null : relationship,
          email: email.isEmpty ? null : email,
          accessLevel: _accessLevel,
          permissions: _permissions.toList(),
          imageFile: _selectedImage,
          removePhoto: _removePhoto,
          careRecipientId: widget.careRecipientId,
        ),
      );
      return;
    }

    context.read<NetworkBloc>().add(
      NetworkAddMemberEvent(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        relationship: relationship.isEmpty ? null : relationship,
        email: email.isEmpty ? null : email,
        accessLevel: _accessLevel,
        permissions: _permissions.toList(),
        imageFile: _selectedImage,
        careRecipientId: widget.careRecipientId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<NetworkBloc, NetworkState>(
      listenWhen: (prev, curr) =>
          prev.addSuccess != curr.addSuccess ||
          prev.updateSuccess != curr.updateSuccess,
      listener: (context, state) {
        if (!state.addSuccess && !state.updateSuccess) return;

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Informações do membro atualizadas com sucesso!'
                  : 'Membro convidado para a rede com sucesso!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textInverse,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: AppColors.background,
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
                _isEditing
                    ? 'Editar membro da Rede de Apoio'
                    : 'Convidar para a Rede de Apoio',
                style: AppTypography.averiaHeadlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Flexible(
              child: AppScrollFade(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoPicker(),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _nameController,
                          label: 'Nome Completo',
                          hint: 'Ex: Dra. Ana Paula',
                          prefixIcon: Icons.person_outline,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Informe o nome.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Telefone / WhatsApp',
                          hint: '(11) 99999-9999',
                          prefixIcon: Icons.phone_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Informe o telefone.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _relationshipController,
                          label: 'Relacionamento (opcional)',
                          hint: 'Ex: Filha, médico ou vizinha',
                          prefixIcon: Icons.people_outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _emailController,
                          label: 'E-mail (opcional)',
                          hint: 'medico@hospital.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _MemberDropdown<NetworkRole>(
                          label: 'Função na Rede',
                          value: _role,
                          items: NetworkRole.values,
                          labelBuilder: (role) => role.label,
                          onChanged: (role) => setState(() => _role = role),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AccessLevelSelector(
                          accessLevel: _accessLevel,
                          permissions: _permissions,
                          onAccessLevelChanged: _onAccessLevelChanged,
                          onPermissionToggled: _onPermissionToggled,
                          errorText: _permissionError,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        BlocBuilder<NetworkBloc, NetworkState>(
                          builder: (context, state) {
                            final isSaving =
                                state.isAddingMember || state.isUpdatingMember;
                            return AppButton(
                              label: _isEditing
                                  ? 'Salvar alterações'
                                  : 'Enviar Convite',
                              onPressed: isSaving ? null : _submit,
                              isLoading: isSaving,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
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

class _MemberDropdown<T> extends StatelessWidget {
  const _MemberDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (item) {
                if (item != null) onChanged(item);
              },
            ),
          ),
        ),
      ],
    );
  }
}

enum _ImageSourceChoice { gallery, camera, remove }
