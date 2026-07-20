import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_tile.dart';

/// Main Chat List Page displaying all network conversations.
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        repository: ChatRepository(),
      )..add(const ChatLoadRoomsEvent()),
      child: const ChatListView(),
    );
  }
}

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.push(AppRoutes.tasks);
        break;
      case 2:
        context.push(AppRoutes.coraChat);
        break;
      case 3:
        // Already on Chat
        break;
      case 4:
        context.push(AppRoutes.sos);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chat & Rede de Apoio',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
            tooltip: 'Gerenciar Rede',
            onPressed: () => context.push(AppRoutes.network),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.status == ChatStatus.loading && state.rooms.isEmpty) {
              return const AppLoading();
            }

            if (state.status == ChatStatus.failure && state.rooms.isEmpty) {
              return AppErrorView(
                message: state.errorMessage ??
                    'Erro ao carregar as conversas.',
                onRetry: () {
                  context.read<ChatBloc>().add(const ChatLoadRoomsEvent());
                },
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                return ChatTile(
                  room: room,
                  onTap: () {
                    context.push(
                      AppRoutes.chatRoom,
                      extra: room,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}
