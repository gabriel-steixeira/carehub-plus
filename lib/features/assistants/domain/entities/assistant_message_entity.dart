/*
 * CareHub Plus — Domínio / Mensagem de Assistente
 *
 * Uma única mensagem da conversa, venha ela da cuidadora ou do assistente.
 * É Dart puro: não conhece Firebase, Flutter nem qual agente está atendendo,
 * então serve para a Cora e para qualquer assistente futuro.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'assistant_quick_reply_entity.dart';

/// Mensagem trocada em um chat de assistente.
///
/// Use os construtores nomeados para deixar a autoria explícita no ponto de uso:
///
/// ```dart
/// AssistantMessage.fromUser(
///   id: 'user_1',
///   text: 'Como está a Vovó Lúcia?',
///   timestamp: DateTime.now(),
/// );
/// ```
class AssistantMessage extends Equatable {
  const AssistantMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.quickReplies = const [],
  });

  /// Mensagem escrita pela cuidadora. Nunca sugere atalhos.
  const AssistantMessage.fromUser({
    required this.id,
    required this.text,
    required this.timestamp,
  }) : isFromUser = true,
       quickReplies = const [];

  /// Resposta do assistente, opcionalmente com atalhos sugeridos.
  const AssistantMessage.fromAssistant({
    required this.id,
    required this.text,
    required this.timestamp,
    this.quickReplies = const [],
  }) : isFromUser = false;

  /// Identificador único da mensagem dentro da conversa.
  final String id;

  /// Conteúdo exibido na bolha.
  final String text;

  /// `true` quando a autoria é da cuidadora; `false` quando é do assistente.
  final bool isFromUser;

  /// Momento em que a mensagem foi criada.
  final DateTime timestamp;

  /// Atalhos sugeridos junto da mensagem. Sempre vazio em mensagens da
  /// cuidadora.
  final List<AssistantQuickReply> quickReplies;

  @override
  List<Object?> get props => [id, text, isFromUser, timestamp, quickReplies];
}
