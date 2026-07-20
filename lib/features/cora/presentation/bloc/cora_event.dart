part of 'cora_bloc.dart';

abstract class CoraEvent extends Equatable {
  const CoraEvent();

  @override
  List<Object?> get props => [];
}

class CoraLoadEvent extends CoraEvent {
  const CoraLoadEvent();
}

class CoraSendMessageEvent extends CoraEvent {
  const CoraSendMessageEvent({required this.messageText});

  final String messageText;

  @override
  List<Object?> get props => [messageText];
}
