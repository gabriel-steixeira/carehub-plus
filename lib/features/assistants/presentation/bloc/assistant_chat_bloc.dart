/*
 * CareHub Plus — Apresentação / BLoC do Chat de Assistente
 *
 * Orquestra a conversa: carrega a abertura, acrescenta o turno da cuidadora,
 * pede a resposta ao repositório e expõe o estado para a tela. Depende apenas
 * do contrato `AssistantRepository`, por isso serve a qualquer assistente.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/caregiver_avatar_repository.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

part 'assistant_chat_event.dart';
part 'assistant_chat_state.dart';

/// Mensagem padrão para falhas que o repositório não soube explicar.
const String _unexpectedErrorMessage =
    'Algo deu errado. Tente novamente em instantes.';

class AssistantChatBloc extends Bloc<AssistantChatEvent, AssistantChatState> {
  AssistantChatBloc({
    required AssistantRepository repository,
    required CaregiverAvatarRepository caregiverRepository,
  }) : _repository = repository,
       _caregiverRepository = caregiverRepository,
       super(const AssistantChatState()) {
    on<AssistantChatLoadEvent>(_onLoad);
    on<AssistantChatSendMessageEvent>(_onSendMessage);
  }

  final AssistantRepository _repository;
  final CaregiverAvatarRepository _caregiverRepository;

  Future<void> _onLoad(
    AssistantChatLoadEvent event,
    Emitter<AssistantChatState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AssistantChatStatus.loading,
        clearErrorMessage: true,
      ),
    );

    // A foto é carregada junto da abertura, mas de forma independente: ela
    // aparece no cabeçalho e nas bolhas do cuidador, e a ausência dela não
    // impede a conversa.
    final caregiverPhotoUrl = await _loadCaregiverPhotoUrl();

    try {
      final messages = await _repository.fetchInitialMessages();
      emit(
        state.copyWith(
          status: AssistantChatStatus.success,
          messages: messages,
          caregiverPhotoUrl: caregiverPhotoUrl,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: AssistantChatStatus.failure,
          errorMessage: e.message,
          caregiverPhotoUrl: caregiverPhotoUrl,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AssistantChatStatus.failure,
          errorMessage: _unexpectedErrorMessage,
          caregiverPhotoUrl: caregiverPhotoUrl,
        ),
      );
    }
  }

  /// Busca a foto do cuidador tolerando falha.
  ///
  /// Sem foto a tela mostra o avatar genérico — não é motivo para bloquear a
  /// conversa nem para exibir tela de erro.
  Future<String?> _loadCaregiverPhotoUrl() async {
    try {
      return await _caregiverRepository.fetchPhotoUrl();
    } on AppException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onSendMessage(
    AssistantChatSendMessageEvent event,
    Emitter<AssistantChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    final userMessage = AssistantMessage.fromUser(
      id: _newMessageId('user'),
      text: text,
      timestamp: DateTime.now(),
    );

    // A mensagem da cuidadora aparece imediatamente; a resposta vem depois.
    final withUserMessage = [...state.messages, userMessage];
    emit(
      state.copyWith(
        status: AssistantChatStatus.success,
        messages: withUserMessage,
        isThinking: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final reply = await _repository.sendMessage(
        text: text,
        intent: event.intent,
        history: withUserMessage,
      );
      emit(
        state.copyWith(
          messages: [...withUserMessage, reply],
          isThinking: false,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(isThinking: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isThinking: false,
          errorMessage: _unexpectedErrorMessage,
        ),
      );
    }
  }

  /// Gera um id local para a mensagem da cuidadora.
  ///
  /// Microssegundos evitam colisão quando duas mensagens saem no mesmo
  /// milissegundo (ex.: dois toques rápidos em atalhos).
  String _newMessageId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}
