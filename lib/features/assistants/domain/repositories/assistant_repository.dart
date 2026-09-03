/*
 * CareHub Plus — Domínio / Contrato de Assistente
 *
 * Define o que qualquer "cérebro" de assistente precisa saber fazer. É este
 * contrato que permite a mesma tela de chat atender a Cora hoje e outro agente
 * amanhã: a apresentação depende desta abstração, nunca de uma implementação
 * concreta.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../entities/assistant_message_entity.dart';

/// Contrato de acesso a um assistente conversacional.
///
/// Cada agente tem sua própria implementação (respostas locais, Firestore,
/// API externa). A camada de apresentação só conhece esta interface.
///
/// ```dart
/// class CoraAssistantRepository implements AssistantRepository { ... }
/// ```
///
/// Toda falha deve ser lançada como `AppException`, para que o BLoC traduza
/// uma mensagem única para a interface.
abstract interface class AssistantRepository {
  /// Mensagens que abrem a conversa (boas-vindas e atalhos iniciais).
  ///
  /// Retorna lista vazia quando o assistente não tem abertura.
  Future<List<AssistantMessage>> fetchInitialMessages();

  /// Envia o turno da cuidadora e devolve a resposta do assistente.
  ///
  /// [text] é sempre o texto exibido na conversa. [intent] vem preenchido
  /// quando a mensagem nasceu de um [AssistantQuickReply]: nesse caso o
  /// assistente deve obedecer à intenção em vez de reinterpretar o texto.
  /// [history] traz a conversa até aqui, incluindo a mensagem atual.
  Future<AssistantMessage> sendMessage({
    required String text,
    required List<AssistantMessage> history,
    String? intent,
  });
}
