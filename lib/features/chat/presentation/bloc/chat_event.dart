part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadRoomsEvent extends ChatEvent {
  const ChatLoadRoomsEvent();
}

class ChatSearchQueryChangedEvent extends ChatEvent {
  const ChatSearchQueryChangedEvent({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

class ChatProfileChangedEvent extends ChatEvent {
  const ChatProfileChangedEvent({this.profileName});

  final String? profileName;

  @override
  List<Object?> get props => [profileName];
}

class ChatCategoryChangedEvent extends ChatEvent {
  const ChatCategoryChangedEvent({this.category});

  final ChatCategory? category;

  @override
  List<Object?> get props => [category];
}

class ChatSortChangedEvent extends ChatEvent {
  const ChatSortChangedEvent({required this.sortOption});

  final ChatSortOption sortOption;

  @override
  List<Object?> get props => [sortOption];
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
