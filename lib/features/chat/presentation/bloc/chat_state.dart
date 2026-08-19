part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, failure }

enum ChatCategory { health, food }

enum ChatSortOption { recent, alphabetical, unread }

/// Identifica a categoria visual de cada assunto usando o conteúdo já salvo.
ChatCategory chatCategoryForRoom(ChatRoomModel room) {
  final content = '${room.title} ${room.lastMessage}'.toLowerCase();
  const foodKeywords = ['ração', 'aliment', 'cardápio', 'comida', 'refeição'];

  return foodKeywords.any(content.contains)
      ? ChatCategory.food
      : ChatCategory.health;
}

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.rooms = const [],
    this.activeRoomId,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedProfileName,
    this.selectedCategory,
    this.sortOption = ChatSortOption.recent,
  });

  final ChatStatus status;
  final List<ChatRoomModel> rooms;
  final String? activeRoomId;
  final List<ChatMessageModel> messages;
  final bool isSending;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedProfileName;
  final ChatCategory? selectedCategory;
  final ChatSortOption sortOption;

  List<String> get profileNames {
    final names = <String>[];
    for (final room in rooms) {
      final name = room.careRecipientName;
      if (name != null && !names.contains(name)) names.add(name);
    }
    return names;
  }

  List<ChatRoomModel> get filteredRooms {
    final query = searchQuery.trim().toLowerCase();
    final filtered = rooms.where((room) {
      final matchesQuery =
          query.isEmpty ||
          '${room.title} ${room.lastMessage} ${room.careRecipientName ?? ''}'
              .toLowerCase()
              .contains(query);
      final matchesProfile =
          selectedProfileName == null ||
          room.careRecipientName == selectedProfileName;
      final matchesCategory =
          selectedCategory == null ||
          chatCategoryForRoom(room) == selectedCategory;
      return matchesQuery && matchesProfile && matchesCategory;
    }).toList();

    switch (sortOption) {
      case ChatSortOption.recent:
        filtered.sort(
          (first, second) =>
              second.lastMessageTime.compareTo(first.lastMessageTime),
        );
      case ChatSortOption.alphabetical:
        filtered.sort((first, second) => first.title.compareTo(second.title));
      case ChatSortOption.unread:
        filtered.sort(
          (first, second) => second.unreadCount.compareTo(first.unreadCount),
        );
    }
    return filtered;
  }

  int get pendingCount => rooms.where((room) => room.unreadCount > 0).length;
  int get completedCount => rooms.where((room) => room.unreadCount == 0).length;

  ChatRoomModel? get activeRoom {
    if (activeRoomId == null || rooms.isEmpty) return null;
    return rooms.firstWhere(
      (room) => room.id == activeRoomId,
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
    String? searchQuery,
    String? selectedProfileName,
    bool clearSelectedProfile = false,
    ChatCategory? selectedCategory,
    bool clearSelectedCategory = false,
    ChatSortOption? sortOption,
  }) {
    return ChatState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProfileName: clearSelectedProfile
          ? null
          : selectedProfileName ?? this.selectedProfileName,
      selectedCategory: clearSelectedCategory
          ? null
          : selectedCategory ?? this.selectedCategory,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rooms,
    activeRoomId,
    messages,
    isSending,
    errorMessage,
    searchQuery,
    selectedProfileName,
    selectedCategory,
    sortOption,
  ];
}
