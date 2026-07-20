part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.rooms = const [],
    this.activeRoomId,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final ChatStatus status;
  final List<ChatRoomModel> rooms;
  final String? activeRoomId;
  final List<ChatMessageModel> messages;
  final bool isSending;
  final String? errorMessage;

  ChatRoomModel? get activeRoom {
    if (activeRoomId == null) return null;
    return rooms.firstWhere(
      (r) => r.id == activeRoomId,
      orElse: () => rooms.first,
    );
  }

  ChatState copyWith({
    ChatStatus? status,
    List<ChatRoomModel>? rooms,
    String? activeRoomId,
    List<ChatMessageModel>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, rooms, activeRoomId, messages, isSending, errorMessage];
}
