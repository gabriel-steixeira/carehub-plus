import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_filter_section.dart';
import '../widgets/chat_tile.dart';

/// Disponibiliza os assuntos de cuidado e seus atalhos de filtragem.
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatBloc(repository: ChatRepository())
            ..add(const ChatLoadRoomsEvent()),
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

  void _showNewTopicUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A criação de assuntos estará disponível em breve.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, String?> _profileAvatars(ChatState state) {
    return {
      for (final profileName in state.profileNames)
        profileName: state.rooms
            .firstWhere((room) => room.careRecipientName == profileName)
            .avatarUrl,
    };
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
                          const ChatLoadRoomsEvent(),
                        ),
                      );
                    }
                    return _ChatContent(
                      state: state,
                      searchController: _searchController,
                      profileAvatars: _profileAvatars(state),
                      onCreateTopic: _showNewTopicUnavailable,
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
  const _ChatContent({
    required this.state,
    required this.searchController,
    required this.profileAvatars,
    required this.onCreateTopic,
  });

  final ChatState state;
  final TextEditingController searchController;
  final Map<String, String?> profileAvatars;
  final VoidCallback onCreateTopic;

  @override
  Widget build(BuildContext context) {
    final rooms = state.filteredRooms;
    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatProfileFilterSection(
            profiles: profileAvatars,
            selectedProfileName: state.selectedProfileName,
            onProfileSelected: (profileName) => context.read<ChatBloc>().add(
              ChatProfileChangedEvent(profileName: profileName),
            ),
            onAddProfile: () => context.go(AppRoutes.home),
          ),
          const SizedBox(height: AppSpacing.md),
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
                      style: AppTypography.displayLarge.copyWith(
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
              _NewTopicButton(onPressed: onCreateTopic),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ChatTopicFilterSection(
            selectedCategory: state.selectedCategory,
            sortOption: state.sortOption,
            onCategorySelected: (category) => context.read<ChatBloc>().add(
              ChatCategoryChangedEvent(category: category),
            ),
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ChatTile(
                  room: room,
                  category: chatCategoryForRoom(room),
                  onTap: () => context.push(AppRoutes.chatRoom, extra: room),
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

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
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
