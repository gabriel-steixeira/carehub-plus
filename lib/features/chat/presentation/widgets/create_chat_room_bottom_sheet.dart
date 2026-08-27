/*
 * CareHub Plus — Apresentação / Criar Novo Assunto
 *
 * Bottom sheet de criação de um assunto de chat, no mesmo padrão visual do
 * `CreateTaskBottomSheet` (Tasks): título, perfil de cuidado vinculado e
 * categoria. Substitui o placeholder "em breve" que existia no botão "+ Nova"
 * de `chat_list_page.dart`.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_member_avatar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../categories/presentation/bloc/care_categories_bloc.dart';
import '../../../categories/presentation/models/category_visuals.dart';
import '../../../network/data/models/network_member_model.dart';
import '../../../network/presentation/bloc/network_bloc.dart';
import '../bloc/chat_bloc.dart';

/// Modal de criação de um novo assunto (sala de conversa).
class CreateChatRoomBottomSheet extends StatefulWidget {
  const CreateChatRoomBottomSheet({
    super.key,
    required this.careRecipientId,
    required this.careRecipientName,
    this.avatarUrl,
  });

  /// Perfil de cuidado ao qual o novo assunto ficará vinculado.
  final String careRecipientId;
  final String careRecipientName;
  final String? avatarUrl;

  static Future<void> show(
    BuildContext context, {
    required String careRecipientId,
    required String careRecipientName,
    String? avatarUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ChatBloc>()),
          BlocProvider.value(value: context.read<CareCategoriesBloc>()),
          BlocProvider.value(value: context.read<NetworkBloc>()),
        ],
        child: CreateChatRoomBottomSheet(
          careRecipientId: careRecipientId,
          careRecipientName: careRecipientName,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  @override
  State<CreateChatRoomBottomSheet> createState() =>
      _CreateChatRoomBottomSheetState();
}

class _CreateChatRoomBottomSheetState extends State<CreateChatRoomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String? _categoryId;
  NetworkMemberModel? _selectedMember;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit(String fallbackCategoryId) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ChatBloc>().add(
      ChatCreateRoomEvent(
        careRecipientId: widget.careRecipientId,
        title: _titleController.text.trim(),
        careRecipientName: widget.careRecipientName,
        categoryId: _categoryId ?? fallbackCategoryId,
        avatarUrl: widget.avatarUrl,
        responsibleMemberId: _selectedMember?.id,
        responsibleMemberName: _selectedMember?.name,
        responsibleMemberPhotoUrl: _selectedMember?.photoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
          prev.isCreatingRoom &&
          !curr.isCreatingRoom &&
          curr.errorMessage == null,
      listener: (context, state) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assunto criado com sucesso!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
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
                'Novo Assunto',
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
                      AppTextField(
                        controller: _titleController,
                        label: 'Título do Assunto',
                        hint: 'Ex: Retorno com o cardiologista',
                        prefixIcon: Icons.forum_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o título.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Responsável pelo assunto (opcional)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ChatMemberSelector(
                        careRecipientId: widget.careRecipientId,
                        selectedMember: _selectedMember,
                        onChanged: (member) =>
                            setState(() => _selectedMember = member),
                      ),
                      const SizedBox(height: AppSpacing.lg),

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
                      const SizedBox(height: AppSpacing.xl),

                      BlocBuilder<ChatBloc, ChatState>(
                        builder: (context, state) {
                          final categories = context
                              .watch<CareCategoriesBloc>()
                              .state
                              .categories;
                          final fallbackId = categories.isNotEmpty
                              ? categories.first.id
                              : 'other';
                          return AppButton(
                            label: 'Criar Assunto',
                            onPressed: state.isCreatingRoom
                                ? null
                                : () => _submit(fallbackId),
                            isLoading: state.isCreatingRoom,
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

class _ChatMemberSelector extends StatelessWidget {
  const _ChatMemberSelector({
    required this.careRecipientId,
    required this.selectedMember,
    required this.onChanged,
  });

  final String careRecipientId;
  final NetworkMemberModel? selectedMember;
  final ValueChanged<NetworkMemberModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    final members = context
        .watch<NetworkBloc>()
        .state
        .members
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
            'Sem responsável',
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
