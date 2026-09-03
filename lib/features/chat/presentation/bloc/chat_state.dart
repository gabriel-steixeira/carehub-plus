part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, failure }

enum ChatSortOption { recent, alphabetical, unread }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.rooms = const [],
    this.profiles = const [],
    this.caregiverPhotoUrl,
    this.activeRoomId,
    this.messages = const [],
    this.isSending = false,
    this.isCreatingRoom = false,
    this.errorMessage,
    this.careRecipientId,
    this.searchQuery = '',
    this.selectedProfileName,
    this.selectedCategoryId,
    this.sortOption = ChatSortOption.recent,
  });

  final ChatStatus status;
  final List<ChatRoomModel> rooms;

  /// Perfis de cuidado reais (Firestore), usados no formulário de criação de
  /// assunto e no filtro de perfil — nunca inferidos apenas das salas já
  /// existentes, senão um perfil sem assunto ainda nunca apareceria.
  final List<CareRecipientModel> profiles;

  /// Foto do cuidador logado — usada no `AppHeader` e no avatar das próprias
  /// mensagens dentro de uma sala.
  final String? caregiverPhotoUrl;
  final String? activeRoomId;
  final List<ChatMessageModel> messages;
  final bool isSending;

  /// `true` enquanto um novo assunto está sendo criado — usado pelo bottom
  /// sheet de criação para desabilitar o botão de salvar.
  final bool isCreatingRoom;
  final String? errorMessage;

  /// Perfil de cuidado ativo usado para consultar e criar assuntos.
  final String? careRecipientId;
  final String searchQuery;
  final String? selectedProfileName;

  /// Id de uma `CareCategoryEntity` (feature `categories/`, compartilhada
  /// com Tasks), ou `null` para "Todos".
  final String? selectedCategoryId;
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
          careRecipientId != null && room.careRecipientId == careRecipientId;
      final matchesProfileName =
          selectedProfileName == null ||
          room.careRecipientName == selectedProfileName;
      final matchesCategory =
          selectedCategoryId == null || room.categoryId == selectedCategoryId;
      return matchesQuery &&
          matchesProfile &&
          matchesProfileName &&
          matchesCategory;
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
    List<CareRecipientModel>? profiles,
    String? caregiverPhotoUrl,
    String? activeRoomId,
    List<ChatMessageModel>? messages,
    bool? isSending,
    bool? isCreatingRoom,
    String? errorMessage,
    String? careRecipientId,
    String? searchQuery,
    String? selectedProfileName,
    bool clearSelectedProfile = false,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    ChatSortOption? sortOption,
  }) {
    return ChatState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      profiles: profiles ?? this.profiles,
      caregiverPhotoUrl: caregiverPhotoUrl ?? this.caregiverPhotoUrl,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isCreatingRoom: isCreatingRoom ?? this.isCreatingRoom,
      errorMessage: errorMessage ?? this.errorMessage,
      careRecipientId: careRecipientId ?? this.careRecipientId,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProfileName: clearSelectedProfile
          ? null
          : selectedProfileName ?? this.selectedProfileName,
      selectedCategoryId: clearSelectedCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rooms,
    profiles,
    caregiverPhotoUrl,
    activeRoomId,
    messages,
    isSending,
    isCreatingRoom,
    errorMessage,
    careRecipientId,
    searchQuery,
    selectedProfileName,
    selectedCategoryId,
    sortOption,
  ];
}
