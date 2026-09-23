import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatRepository repository, HomeRepository? homeRepository})
    : _repository = repository,
      _homeRepository = homeRepository ?? HomeRepository(),
      super(const ChatState()) {
    on<ChatLoadRoomsEvent>(_onLoadRooms);
    on<ChatSearchQueryChangedEvent>(_onSearchQueryChanged);
    on<ChatProfileChangedEvent>(_onProfileChanged);
    on<ChatCategoryChangedEvent>(_onCategoryChanged);
    on<ChatSortChangedEvent>(_onSortChanged);
    on<ChatOpenRoomEvent>(_onOpenRoom);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatCreateRoomEvent>(_onCreateRoom);
  }

  final ChatRepository _repository;
  final HomeRepository _homeRepository;

  Future<void> _onLoadRooms(
    ChatLoadRoomsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final caregiver = await _homeRepository.fetchCaregiver();
      final profiles = await _homeRepository.fetchCareRecipients();
      final selectedProfileId =
          event.careRecipientId ?? profiles.firstOrNull?.id;
      final rooms = selectedProfileId == null
          ? const <ChatRoomModel>[]
          : await _repository.fetchChatRooms(
              careRecipientId: selectedProfileId,
            );
      final selectedProfile = profiles
          .where((profile) => profile.id == selectedProfileId)
          .firstOrNull;

      emit(
        state.copyWith(
          status: ChatStatus.success,
          rooms: rooms,
          profiles: profiles,
          caregiverPhotoUrl: caregiver.photoUrl,
          caregiverPhotoBase64: caregiver.photoBase64,
          careRecipientId: selectedProfileId,
          selectedProfileName: selectedProfile?.name,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  void _onSearchQueryChanged(
    ChatSearchQueryChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onProfileChanged(
    ChatProfileChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        selectedProfileName: event.profileName,
        clearSelectedProfile: event.profileName == null,
      ),
    );
  }

  void _onCategoryChanged(
    ChatCategoryChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearSelectedCategory: event.categoryId == null,
      ),
    );
  }

  void _onSortChanged(ChatSortChangedEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(sortOption: event.sortOption));
  }

  Future<void> _onOpenRoom(
    ChatOpenRoomEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(activeRoomId: event.roomId, status: ChatStatus.loading),
    );
    try {
      // Carrega a foto do cuidador se ainda não foi carregada
      if (state.caregiverPhotoUrl == null && state.caregiverPhotoBase64 == null) {
        final caregiver = await _homeRepository.fetchCaregiver();
        final messages = await _repository.fetchMessages(event.roomId);
        emit(
          state.copyWith(
            status: ChatStatus.success,
            messages: messages,
            caregiverPhotoUrl: caregiver.photoUrl,
            caregiverPhotoBase64: caregiver.photoBase64,
          ),
        );
      } else {
        final messages = await _repository.fetchMessages(event.roomId);
        emit(state.copyWith(status: ChatStatus.success, messages: messages));
      }
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
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
      final updatedMessages = List<ChatMessageModel>.from(state.messages)
        ..add(newMsg);

      emit(state.copyWith(messages: updatedMessages, isSending: false));
    } catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateRoom(
    ChatCreateRoomEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isCreatingRoom: true));
    try {
      final newRoom = await _repository.addRoom(
        careRecipientId: event.careRecipientId,
        title: event.title,
        careRecipientName: event.careRecipientName,
        categoryId: event.categoryId,
        avatarUrl: event.avatarUrl,
        responsibleMemberId: event.responsibleMemberId,
        responsibleMemberName: event.responsibleMemberName,
        responsibleMemberPhotoUrl: event.responsibleMemberPhotoUrl,
      );
      emit(
        state.copyWith(rooms: [newRoom, ...state.rooms], isCreatingRoom: false),
      );
    } catch (e) {
      emit(state.copyWith(isCreatingRoom: false, errorMessage: e.toString()));
    }
  }
}
