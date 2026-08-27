/*
 * CareHub Plus — Dados / Cérebro da Cora
 *
 * Implementação do contrato `AssistantRepository` para a assistente Cora.
 * As respostas ainda são locais e simuladas (não há API de IA no projeto):
 * quando existir, só este arquivo muda — tela e BLoC continuam iguais.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

/// Assuntos que a Cora sabe responder.
///
/// Fonte única dos identificadores: os atalhos enviam estes valores e é por
/// eles que [CoraAssistantRepository] decide a resposta. Rótulo e intenção
/// nunca saem de sincronia porque ninguém repete a string à mão.
abstract final class _CoraIntents {
  static const String careRecipientSummary = 'cora.care_recipient_summary';
  static const String petReminders = 'cora.pet_reminders';
  static const String medications = 'cora.medications';
  static const String healthTips = 'cora.health_tips';
}

/// Atalhos reutilizados entre as respostas.
const _careRecipientReply = AssistantQuickReply(
  label: 'Resumo da Vovó Lúcia',
  intent: _CoraIntents.careRecipientSummary,
);

const _petRemindersReply = AssistantQuickReply(
  label: 'Lembretes da Yuna (Pet)',
  intent: _CoraIntents.petReminders,
);

const _medicationsReply = AssistantQuickReply(
  label: 'Próximas medicações',
  intent: _CoraIntents.medications,
);

const _healthTipsReply = AssistantQuickReply(
  label: 'Dicas de saúde',
  intent: _CoraIntents.healthTips,
);

/// Cora — assistente proativa de cuidados do CareHub+.
class CoraAssistantRepository implements AssistantRepository {
  /// Latência simulada da abertura da conversa.
  static const Duration _openingDelay = Duration(milliseconds: 300);

  /// Latência simulada de uma resposta, o que dá sentido ao "analisando...".
  static const Duration _replyDelay = Duration(milliseconds: 800);

  @override
  Future<List<AssistantMessage>> fetchInitialMessages() async {
    await Future<void>.delayed(_openingDelay);

    return [
      AssistantMessage.fromAssistant(
        id: _newMessageId(),
        text:
            'Olá! Eu sou a Cora, sua assistente proativa de cuidados no '
            'CareHub+. Como posso te ajudar hoje?',
        timestamp: DateTime.now(),
        quickReplies: const [
          _careRecipientReply,
          _petRemindersReply,
          _medicationsReply,
          _healthTipsReply,
        ],
      ),
    ];
  }

  @override
  Future<AssistantMessage> sendMessage({
    required String text,
    required List<AssistantMessage> history,
    String? intent,
  }) async {
    await Future<void>.delayed(_replyDelay);

    // O atalho já manda a intenção pronta; texto livre precisa ser interpretado.
    return _answerFor(intent ?? _intentFromText(text));
  }

  /// Interpretação simples de texto livre por palavra-chave.
  String _intentFromText(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('vovó') || normalized.contains('lúcia')) {
      return _CoraIntents.careRecipientSummary;
    }
    if (normalized.contains('yuna') || normalized.contains('pet')) {
      return _CoraIntents.petReminders;
    }
    if (normalized.contains('medica') || normalized.contains('remédio')) {
      return _CoraIntents.medications;
    }
    if (normalized.contains('dica') || normalized.contains('saúde')) {
      return _CoraIntents.healthTips;
    }
    return _unknownIntent;
  }

  /// Monta a resposta da Cora para uma intenção já resolvida.
  ///
  /// Intenção desconhecida cai no caso padrão, que reapresenta os atalhos —
  /// a conversa nunca fica sem saída.
  AssistantMessage _answerFor(String intent) {
    final (text, quickReplies) = switch (intent) {
      _CoraIntents.careRecipientSummary => (
        'Vovó Lúcia está com todas as medicações em dia hoje! A pressão foi '
            'aferida às 08h. A próxima medicação de pressão será às 20h.',
        const [_medicationsReply, _healthTipsReply],
      ),
      _CoraIntents.petReminders => (
        'A Yuna tomou a ração matinal! Lembrete: a vacina V10 precisa de '
            'reforço em 15 dias.',
        const [_medicationsReply, _careRecipientReply],
      ),
      _CoraIntents.medications => (
        'Temos 1 medicação agendada para hoje às 20h: anti-hipertensivo '
            '(Losartana 50mg) para a Vovó Lúcia.',
        const [_careRecipientReply, _petRemindersReply],
      ),
      _CoraIntents.healthTips => (
        'Dica da Cora: uma rotina de hidratação regular e caminhadas curtas '
            'pela manhã ajuda a circulação e o humor.',
        const [_careRecipientReply, _petRemindersReply],
      ),
      _ => (
        'Entendi! Estou acompanhando a rotina de cuidados do CareHub+. Posso '
            'resumir o dia, lembrar das medicações ou dar orientações de saúde.',
        const [_careRecipientReply, _petRemindersReply, _medicationsReply],
      ),
    };

    return AssistantMessage.fromAssistant(
      id: _newMessageId(),
      text: text,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
    );
  }

  String _newMessageId() => 'cora_${DateTime.now().microsecondsSinceEpoch}';
}

/// Intenção usada quando a Cora não reconhece o pedido.
const String _unknownIntent = 'cora.unknown';
