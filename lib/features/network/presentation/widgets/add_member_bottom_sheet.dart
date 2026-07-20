import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/network_member_model.dart';
import '../bloc/network_bloc.dart';

/// Modal to invite/add a new member to the support network.
class AddMemberBottomSheet extends StatefulWidget {
  const AddMemberBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<NetworkBloc>(),
        child: const AddMemberBottomSheet(),
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
  final _emailController = TextEditingController();

  NetworkRole _role = NetworkRole.caregiver;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<NetworkBloc>().add(
          NetworkAddMemberEvent(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _role,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<NetworkBloc, NetworkState>(
      listenWhen: (prev, curr) => prev.addSuccess != curr.addSuccess,
      listener: (context, state) {
        if (state.addSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Membro convidado para a rede com sucesso!',
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
                'Convidar para a Rede de Apoio',
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
                      // Name
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

                      // Phone
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

                      // Email
                      AppTextField(
                        controller: _emailController,
                        label: 'E-mail (opcional)',
                        hint: 'medico@hospital.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Role Selector
                      Text(
                        'Função na Rede',
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<NetworkRole>(
                            value: _role,
                            isExpanded: true,
                            items: NetworkRole.values.map((r) {
                              return DropdownMenuItem(
                                value: r,
                                child: Text(r.label,
                                    style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _role = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      BlocBuilder<NetworkBloc, NetworkState>(
                        builder: (context, state) {
                          return AppButton(
                            label: 'Enviar Convite',
                            onPressed: state.isAddingMember ? null : _submit,
                            isLoading: state.isAddingMember,
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
