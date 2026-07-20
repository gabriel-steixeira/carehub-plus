import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatRepository repository})
      : _repository = repository,
        super(const ChatState()) {
    on<ChatLoadRoomsEvent>(_onLoadRooms);
    on<ChatOpenRoomEvent>(_onOpenRoom);
    on<ChatSendMessageEvent>(_onSendMessage);
  }

  final ChatRepository _repository;

  Future<void> _onLoadRooms(
    ChatLoadRoomsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final rooms = await _repository.fetchChatRooms();
      emit(state.copyWith(status: ChatStatus.success, rooms: rooms));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOpenRoom(
    ChatOpenRoomEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(activeRoomId: event.roomId, status: ChatStatus.loading));
    try {
      final messages = await _repository.fetchMessages(event.roomId);
      emit(state.copyWith(status: ChatStatus.success, messages: messages));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.text.trim().isEmpty) return;

    emit(state.copyWith(isSending: true));
    try {
      final newMsg = await _repository.sendMessage(
        event.roomId,
        event.text.trim(),
        type: event.type,
      );

      final updatedMessages = List<ChatMessageModel>.from(state.messages)..add(newMsg);

      emit(state.copyWith(
        messages: updatedMessages,
        isSending: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
