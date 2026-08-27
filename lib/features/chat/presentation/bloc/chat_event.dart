part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadRoomsEvent extends ChatEvent {
  const ChatLoadRoomsEvent({this.careRecipientId});

  final String? careRecipientId;

  @override
  List<Object?> get props => [careRecipientId];
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
  const ChatCategoryChangedEvent({this.categoryId});

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
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

/// Cria um novo assunto (sala de conversa) para um Care Recipient.
class ChatCreateRoomEvent extends ChatEvent {
  const ChatCreateRoomEvent({
    required this.careRecipientId,
    required this.title,
    required this.careRecipientName,
    required this.categoryId,
    this.avatarUrl,
    this.responsibleMemberId,
    this.responsibleMemberName,
    this.responsibleMemberPhotoUrl,
  });

  final String careRecipientId;
  final String title;
  final String careRecipientName;
  final String categoryId;
  final String? avatarUrl;
  final String? responsibleMemberId;
  final String? responsibleMemberName;
  final String? responsibleMemberPhotoUrl;

  @override
  List<Object?> get props => [
    careRecipientId,
    title,
    careRecipientName,
    categoryId,
    avatarUrl,
    responsibleMemberId,
    responsibleMemberName,
    responsibleMemberPhotoUrl,
  ];
}
