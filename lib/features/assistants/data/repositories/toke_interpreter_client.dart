/*
 * CareHub Plus — Dados / Triagem do Toke no backend
 *
 * Envia a mensagem, o histórico curto e o contexto da conta para a função
 * `tokeInterpret`, que chama o Gemini no servidor. A chave do Gemini não
 * existe mais no app; este cliente só conhece o formato da resposta.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../../../services/cloud_functions_service.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/support_intent_entity.dart';

/// Cliente da triagem do Toke.
class TokeInterpreterClient {
  TokeInterpreterClient({CallableClient? client})
    : _client = client ?? CloudFunctionsService();

  static const String _function = 'tokeInterpret';
  static const int _historyLimit = 10;

  final CallableClient _client;

  /// Interpreta [text]. Lança `AppException` com a mensagem do backend.
  Future<SupportIntentResult> interpret({
    required String text,
    required List<AssistantMessage> history,
    required Map<String, dynamic> context,
    required List<String> planIds,
  }) async {
    final data = await _client.call(_function, {
      'text': text,
      'history': _mapHistory(history, currentText: text),
      'context': context,
      'planIds': planIds,
    });

    String? field(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return SupportIntentResult(
      kind: SupportIntentKind.fromValue(field('kind')),
      reply: field('reply') ?? 'Desculpe, não consegui entender. Pode reformular?',
      planId: field('planId'),
      billingCycle: field('billingCycle'),
      paymentType: field('paymentType'),
      summary: field('summary'),
    );
  }

  /// Conversa anterior, sem a mensagem atual e começando por uma fala da
  /// pessoa — o mesmo recorte que o app já enviava ao Gemini.
  List<Map<String, String>> _mapHistory(
    List<AssistantMessage> history, {
    required String currentText,
  }) {
    final previous = List<AssistantMessage>.of(history);
    if (previous.isNotEmpty &&
        previous.last.isFromUser &&
        previous.last.text.trim() == currentText.trim()) {
      previous.removeLast();
    }
    while (previous.isNotEmpty && !previous.first.isFromUser) {
      previous.removeAt(0);
    }

    final recent = previous.length > _historyLimit
        ? previous.sublist(previous.length - _historyLimit)
        : previous;
    return recent
        .map(
          (message) => {
            'role': message.isFromUser ? 'user' : 'model',
            'text': message.text,
          },
        )
        .toList();
  }
}
