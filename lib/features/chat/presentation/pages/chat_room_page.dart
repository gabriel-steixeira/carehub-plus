/*
 * CareHub Plus — Apresentação / Sala de Conversa
 *
 * Conversa entre pessoas reais (cuidador, rede de apoio, profissional de
 * saúde) sobre um assunto. Reaproveita a casca visual do chat da Cora
 * (`AppHeader`, `AppIdentityCard`, `AppChatInputBar`): o cartão de identidade
 * mostra a foto de quem escreveu por último — não um mascote fixo — e a cor
 * vem da categoria do assunto, não de um rosa fixo. A conversa em si segue
 * ligada ao `ChatBloc`/Firestore: é uma sala real, não a "IA" da Cora.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_chat_input_bar.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_identity_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../categories/data/repositories/care_categories_repository.dart';
import '../../../categories/domain/entities/care_category_entity.dart';
import '../../../categories/presentation/bloc/care_categories_bloc.dart';
import '../../../categories/presentation/models/category_visuals.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble.dart';

/// Tela de uma sala de conversa (assunto) já aberta.
class ChatRoomPage extends StatelessWidget {
  const ChatRoomPage({super.key, required this.room});

  final ChatRoomModel room;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ChatBloc(repository: ChatRepository())
                ..add(ChatOpenRoomEvent(roomId: room.id)),
        ),
        BlocProvider(
          create: (context) =>
              CareCategoriesBloc(repository: CareCategoriesRepository())
                ..add(const CareCategoriesLoadEvent()),
        ),
      ],
      child: ChatRoomView(room: room),
    );
  }
}

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({super.key, required this.room});

  final ChatRoomModel room;

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  void _sendMessage({ChatMessageType type = ChatMessageType.text}) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(
      ChatSendMessageEvent(roomId: widget.room.id, text: text, type: type),
    );
    _textController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            BlocSelector<ChatBloc, ChatState, ({String? photoUrl, String? photoBase64})>(
              selector: (state) => (
                photoUrl: state.caregiverPhotoUrl,
                photoBase64: state.caregiverPhotoBase64,
              ),
              builder: (context, photo) => AppHeader(
                photoUrl: photo.photoUrl,
                photoBase64: photo.photoBase64,
                showSettings: false,
                leading: BackButton(
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
                  builder: (context, categoriesState) {
                    final category = categoriesState.categories.firstWhere(
                      (c) => c.id == widget.room.categoryId,
                      orElse: () => categoriesState.categories.isNotEmpty
                          ? categoriesState.categories.last
                          : const _FallbackCategory(),
                    );

                    return Column(
                      children: [
                        AppIdentityCard(
                          imageAsset: 'assets/images/logo_pequeno.png',
                          imageUrl:
                              widget.room.responsibleMemberPhotoUrl ??
                              widget.room.avatarUrl,
                          showAvatar: true,
                          title: widget.room.title,
                          role: widget.room.responsibleMemberName,
                          subtitle: category.label,
                          tint: colorForCategory(category),
                          margin: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                        ),
                        Expanded(child: _buildMessages(category)),
                        AppChatInputBar(
                          controller: _textController,
                          hintText: 'Digite uma mensagem...',
                          sendButtonColor: AppColors.tintPink,
                          onSend: _sendMessage,
                          leading: IconButton(
                            icon: Icon(
                              Icons.health_and_safety_outlined,
                              color: colorForCategory(category),
                            ),
                            tooltip: 'Enviar Nota de Saúde',
                            onPressed: () =>
                                _sendMessage(type: ChatMessageType.medicalNote),
                          ),
                        ),
                      ],
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

  Widget _buildMessages(CareCategoryEntity category) {
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length,
      listener: (context, state) => _scrollToBottom(),
      builder: (context, state) {
        if (state.status == ChatStatus.loading && state.messages.isEmpty) {
          return const AppLoading();
        }

        final accentColor = colorForCategory(category);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const BouncingScrollPhysics(),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final message = state.messages[index];
            return MessageBubble(
              message: message,
              accentColor: accentColor,
              senderAvatarUrl:
                  widget.room.responsibleMemberPhotoUrl ??
                  widget.room.avatarUrl,
              caregiverAvatarUrl: state.caregiverPhotoUrl,
              caregiverAvatarBase64: state.caregiverPhotoBase64,
            );
          },
        );
      },
    );
  }
}

/// Categoria neutra usada apenas quando a lista de categorias ainda não
/// carregou — nunca persistida, só evita um crash visual momentâneo.
class _FallbackCategory extends CareCategoryEntity {
  const _FallbackCategory()
    : super(id: 'other', label: 'Outro', iconKey: 'other', colorKey: 'grey');
}
