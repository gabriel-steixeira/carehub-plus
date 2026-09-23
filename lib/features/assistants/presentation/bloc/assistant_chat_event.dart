part of 'assistant_chat_bloc.dart';

abstract class AssistantChatEvent extends Equatable {
  const AssistantChatEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega a abertura da conversa. Também usado no "tentar novamente".
class AssistantChatLoadEvent extends AssistantChatEvent {
  const AssistantChatLoadEvent();
}

/// Envia um turno da cuidadora ao assistente.
class AssistantChatSendMessageEvent extends AssistantChatEvent {
  const AssistantChatSendMessageEvent({required this.text, this.intent});

  /// Texto digitado ou rótulo do atalho tocado.
  final String text;

  /// Intenção do atalho, quando a mensagem nasceu de um chip.
  final String? intent;

  @override
  List<Object?> get props => [text, intent];
}
