part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadRoomsEvent extends ChatEvent {
  const ChatLoadRoomsEvent();
}

class ChatOpenRoomEvent extends ChatEvent {
  const ChatOpenRoomEvent({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

class ChatSendMessageEvent extends ChatEvent {
  const ChatSendMessageEvent({
    required this.roomId,
    required this.text,
    this.type = ChatMessageType.text,
  });

  final String roomId;
  final String text;
  final ChatMessageType type;

  @override
  List<Object?> get props => [roomId, text, type];
}
