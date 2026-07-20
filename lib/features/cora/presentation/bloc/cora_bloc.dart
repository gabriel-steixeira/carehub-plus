import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/cora_message_model.dart';
import '../../data/repositories/cora_repository.dart';

part 'cora_event.dart';
part 'cora_state.dart';

class CoraBloc extends Bloc<CoraEvent, CoraState> {
  CoraBloc({required CoraRepository repository})
      : _repository = repository,
        super(const CoraState()) {
    on<CoraLoadEvent>(_onLoad);
    on<CoraSendMessageEvent>(_onSendMessage);
  }

  final CoraRepository _repository;

  Future<void> _onLoad(
    CoraLoadEvent event,
    Emitter<CoraState> emit,
  ) async {
    emit(state.copyWith(status: CoraStatus.loading));
    try {
      final initial = await _repository.fetchInitialMessages();
      emit(state.copyWith(status: CoraStatus.success, messages: initial));
    } catch (e) {
      emit(state.copyWith(
        status: CoraStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSendMessage(
    CoraSendMessageEvent event,
    Emitter<CoraState> emit,
  ) async {
    final text = event.messageText.trim();
    if (text.isEmpty) return;

    final userMsg = CoraMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedList = List<CoraMessageModel>.from(state.messages)..add(userMsg);
    emit(state.copyWith(messages: updatedList, isThinking: true));

    try {
      final coraReply = await _repository.sendMessage(text, updatedList);
      final finalMessages = List<CoraMessageModel>.from(updatedList)..add(coraReply);

      emit(state.copyWith(messages: finalMessages, isThinking: false));
    } catch (e) {
      emit(state.copyWith(isThinking: false, errorMessage: e.toString()));
    }
  }
}
