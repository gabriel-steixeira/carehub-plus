part of 'assistant_chat_bloc.dart';

enum AssistantChatStatus { initial, loading, success, failure }

class AssistantChatState extends Equatable {
  const AssistantChatState({
    this.status = AssistantChatStatus.initial,
    this.messages = const [],
    this.isThinking = false,
    this.errorMessage,
    this.caregiverPhotoUrl,
  });

  final AssistantChatStatus status;

  /// Conversa em ordem cronológica.
  final List<AssistantMessage> messages;

  /// `true` enquanto o assistente prepara a resposta.
  final bool isThinking;

  /// Motivo da última falha, ou `null` quando não há erro pendente.
  final String? errorMessage;

  /// Foto do cuidador logado, usada no cabeçalho e nas bolhas dele.
  ///
  /// `null` quando a conta não tem foto: a interface cai no avatar genérico.
  final String? caregiverPhotoUrl;

  /// `true` quando a tela já tem conversa para exibir.
  bool get hasMessages => messages.isNotEmpty;

  /// Copia o estado alterando apenas os campos informados.
  ///
  /// [clearErrorMessage] existe porque `errorMessage ?? this.errorMessage`
  /// nunca conseguiria voltar o campo para `null`: sem essa opção, um erro
  /// antigo ficaria preso no estado para sempre.
  AssistantChatState copyWith({
    AssistantChatStatus? status,
    List<AssistantMessage>? messages,
    bool? isThinking,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? caregiverPhotoUrl,
  }) {
    return AssistantChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      caregiverPhotoUrl: caregiverPhotoUrl ?? this.caregiverPhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    isThinking,
    errorMessage,
    caregiverPhotoUrl,
  ];
}
