part of 'cora_bloc.dart';

enum CoraStatus { initial, loading, success, failure }

class CoraState extends Equatable {
  const CoraState({
    this.status = CoraStatus.initial,
    this.messages = const [],
    this.isThinking = false,
    this.errorMessage,
  });

  final CoraStatus status;
  final List<CoraMessageModel> messages;
  final bool isThinking;
  final String? errorMessage;

  CoraState copyWith({
    CoraStatus? status,
    List<CoraMessageModel>? messages,
    bool? isThinking,
    String? errorMessage,
  }) {
    return CoraState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, isThinking, errorMessage];
}
