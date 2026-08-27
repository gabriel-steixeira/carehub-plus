/*
 * CareHub Plus — Apresentação / Tela de Chat de Assistente
 *
 * Esqueleto visual da conversa, igual para qualquer agente: cabeçalho, cartão
 * de identidade, lista de mensagens com seus três estados (carregando, erro e
 * vazio) e barra de escrita. O que muda de assistente para assistente entra
 * por `AssistantProfile`; o comportamento vem do BLoC injetado acima.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_identity_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_chat_input_bar.dart';
import '../../../../shared/widgets/app_scroll_fade.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../bloc/assistant_chat_bloc.dart';
import '../models/assistant_profile.dart';
import 'assistant_message_bubble.dart';
import 'assistant_thinking_indicator.dart';

/// Conversa com um assistente. Espera um [AssistantChatBloc] acima na árvore.
class AssistantChatView extends StatefulWidget {
  const AssistantChatView({
    super.key,
    required this.profile,
    this.bottomNavIndex,
  });

  /// Identidade do agente exibido.
  final AssistantProfile profile;

  /// Item destacado na barra inferior, quando o agente tem um.
  final int? bottomNavIndex;

  @override
  State<AssistantChatView> createState() => _AssistantChatViewState();
}

class _AssistantChatViewState extends State<AssistantChatView> {
  /// Valor fora da faixa de índices: nenhum item da barra fica destacado.
  static const int _noNavSelection = -1;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Envia o texto digitado no campo.
  void _sendTypedMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<AssistantChatBloc>().add(
      AssistantChatSendMessageEvent(text: text),
    );
    _textController.clear();
  }

  /// Envia um atalho sugerido, preservando a intenção original.
  void _sendQuickReply(AssistantQuickReply quickReply) {
    context.read<AssistantChatBloc>().add(
      AssistantChatSendMessageEvent(
        text: quickReply.label,
        intent: quickReply.intent,
      ),
    );
  }

  /// Rola até a última mensagem depois que o frame novo já foi medido.
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

  void _onBottomNavTap(int index) {
    // Tocar no item da própria tela não navega para lugar nenhum.
    if (index == widget.bottomNavIndex) return;

    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.tasks);
      case 2:
        context.push(AppRoutes.coraChat);
      case 3:
        context.push(AppRoutes.chat);
      case 4:
        context.push(AppRoutes.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            // BlocSelector em vez de BlocBuilder: o cabeçalho só reconstrói
            // quando a foto muda, e não a cada mensagem da conversa.
            BlocSelector<AssistantChatBloc, AssistantChatState, String?>(
              selector: (state) => state.caregiverPhotoUrl,
              builder: (context, caregiverPhotoUrl) =>
                  AppHeader(photoUrl: caregiverPhotoUrl),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: Column(
                  children: [
                    AppIdentityCard(
                      imageAsset: profile.avatarAsset,
                      title: profile.name,
                      role: profile.role,
                      subtitle: profile.subtitle,
                      tint: profile.tint,
                      margin: EdgeInsets.only(
                        left: context.pagePaddingHorizontal,
                        right: context.pagePaddingHorizontal,
                        top: context.pagePaddingVertical,
                      ),
                    ),
                    Expanded(child: _buildConversation(profile)),
                    AppChatInputBar(
                      controller: _textController,
                      hintText: profile.inputHint,
                      onSend: _sendTypedMessage,
                      sendButtonColor: profile.accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: widget.bottomNavIndex ?? _noNavSelection,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildConversation(AssistantProfile profile) {
    return BlocConsumer<AssistantChatBloc, AssistantChatState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.isThinking != current.isThinking ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        _scrollToBottom();

        // Falha no meio da conversa não pode apagar o histórico: avisa em
        // SnackBar e mantém o que já foi conversado na tela.
        final error = state.errorMessage;
        if (error != null && state.hasMessages) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error)));
        }
      },
      builder: (context, state) {
        if (!state.hasMessages) {
          switch (state.status) {
            case AssistantChatStatus.initial:
            case AssistantChatStatus.loading:
              return const AppLoading();
            case AssistantChatStatus.failure:
              return AppErrorView(
                message: state.errorMessage ?? profile.errorMessage,
                onRetry: () => context.read<AssistantChatBloc>().add(
                  const AssistantChatLoadEvent(),
                ),
              );
            case AssistantChatStatus.success:
              if (!state.isThinking) {
                return AppEmptyView(
                  message:
                      'Nenhuma mensagem por aqui ainda. '
                      'Escreva a primeira para começar.',
                  icon: Icons.chat_bubble_outline_rounded,
                );
              }
          }
        }

        return AppScrollFade(child: _buildMessageList(state, profile));
      },
    );
  }

  Widget _buildMessageList(AssistantChatState state, AssistantProfile profile) {
    final horizontalPadding = context.pagePaddingHorizontal;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.lg,
            horizontalPadding,
            AppSpacing.md,
          ),
          itemCount: state.messages.length + (state.isThinking ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.messages.length) {
              return AssistantThinkingIndicator(
                avatarAsset: profile.avatarAsset,
                label: profile.thinkingLabel,
                accentColor: profile.accentColor ?? AppColors.primary,
              );
            }

            return AssistantMessageBubble(
              message: state.messages[index],
              profile: profile,
              caregiverPhotoUrl: state.caregiverPhotoUrl,
              onQuickReplyTap: _sendQuickReply,
            );
          },
        ),
      ),
    );
  }
}
