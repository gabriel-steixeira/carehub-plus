import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/categories/data/repositories/care_categories_repository.dart';
import '../../../../features/categories/presentation/bloc/care_categories_bloc.dart';
import '../../../../features/categories/domain/entities/care_category_entity.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/category_chip_selector.dart';
import '../../../../shared/widgets/manage_categories_bottom_sheet.dart';
import '../../../dashboard/presentation/widgets/active_profile_chip.dart';
import '../../../network/data/repositories/network_repository.dart';
import '../../../network/presentation/bloc/network_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_filter_section.dart';
import '../widgets/chat_tile.dart';
import '../widgets/create_chat_room_bottom_sheet.dart';

/// Disponibiliza os assuntos de cuidado e seus atalhos de filtragem.
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key, this.careRecipientId});

  final String? careRecipientId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ChatBloc(repository: ChatRepository())
                ..add(ChatLoadRoomsEvent(careRecipientId: careRecipientId)),
        ),
        BlocProvider(
          create: (context) =>
              NetworkBloc(repository: NetworkRepository())
                ..add(const NetworkLoadEvent()),
        ),
        BlocProvider(
          create: (context) =>
              CareCategoriesBloc(repository: CareCategoriesRepository())
                ..add(const CareCategoriesLoadEvent()),
        ),
      ],
      child: const ChatListView(),
    );
  }
}

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.tasks);
      case 2:
        context.push(AppRoutes.coraChat);
      case 3:
        break;
      case 4:
        context.push(AppRoutes.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.status == ChatStatus.loading &&
                        state.rooms.isEmpty) {
                      return const AppLoading();
                    }
                    if (state.status == ChatStatus.failure &&
                        state.rooms.isEmpty) {
                      return AppErrorView(
                        message:
                            state.errorMessage ??
                            'Erro ao carregar os assuntos.',
                        onRetry: () => context.read<ChatBloc>().add(
                          ChatLoadRoomsEvent(
                            careRecipientId: state.careRecipientId,
                          ),
                        ),
                      );
                    }
                    return _ChatContent(
                      state: state,
                      searchController: _searchController,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}

class _ChatContent extends StatelessWidget {
  const _ChatContent({required this.state, required this.searchController});

  final ChatState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final rooms = state.filteredRooms;

    // Resolve o perfil selecionado a partir do nome armazenado no estado.
    final selectedProfile = state.profiles.isEmpty
        ? null
        : state.profiles
                  .where((p) => p.id == state.careRecipientId)
                  .firstOrNull ??
              state.profiles.first;

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedProfile != null) ...[
            ActiveProfileChip(
              profile: selectedProfile,
              onChangeTap: () => context.go(AppRoutes.home),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSearchField(
            hintText: 'Buscar assuntos',
            controller: searchController,
            onChanged: (query) => context.read<ChatBloc>().add(
              ChatSearchQueryChangedEvent(query: query),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assuntos',
                      style: AppTypography.averiaDisplayLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${state.pendingCount} pendentes, ${state.completedCount} concluídos',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _NewTopicButton(
                onPressed: state.careRecipientId == null
                    ? null
                    : () => CreateChatRoomBottomSheet.show(
                        context,
                        careRecipientId: state.careRecipientId!,
                        careRecipientName: selectedProfile?.name ?? '',
                        avatarUrl: selectedProfile?.photoUrl,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
            builder: (context, categoriesState) {
              return CategoryChipSelector(
                categories: categoriesState.categories,
                selectedCategoryId: state.selectedCategoryId,
                onCategorySelected: (categoryId) => context
                    .read<ChatBloc>()
                    .add(ChatCategoryChangedEvent(categoryId: categoryId)),
                onManageCategories: () =>
                    ManageCategoriesBottomSheet.show(context),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ChatSortDropdown(
            sortOption: state.sortOption,
            onSortSelected: (sortOption) => context.read<ChatBloc>().add(
              ChatSortChangedEvent(sortOption: sortOption),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: AppEmptyView(
                message:
                    'Nenhum assunto encontrado para os filtros selecionados.',
                icon: Icons.forum_outlined,
              ),
            )
          else
            BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
              builder: (context, categoriesState) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final category = categoriesState.categories.firstWhere(
                      (c) => c.id == room.categoryId,
                      orElse: () => categoriesState.categories.isNotEmpty
                          ? categoriesState.categories.last
                          : const _FallbackCategory(),
                    );
                    return ChatTile(
                      room: room,
                      category: category,
                      onTap: () =>
                          context.push(AppRoutes.chatRoom, extra: room),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _NewTopicButton extends StatelessWidget {
  const _NewTopicButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? AppColors.border : AppColors.primary,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: AppColors.textInverse),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Nova',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Categoria neutra usada apenas quando a lista de categorias ainda não
/// carregou — nunca persistida, só evita um crash visual momentâneo.
class _FallbackCategory extends CareCategoryEntity {
  const _FallbackCategory()
    : super(id: 'other', label: 'Outro', iconKey: 'other', colorKey: 'grey');
}
