/*
 * CareHub Plus — Dados / Cérebro do Toke
 *
 * Implementação local do concierge Toke. Oferece orientações sobre o app,
 * conta, planos e suporte sem acoplar a conversa a Firebase ou à interface.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

/// Assuntos de suporte reconhecidos pelo Toke.
abstract final class _TokeIntents {
  static const String appGuidance = 'toke.app_guidance';
  static const String accountHelp = 'toke.account_help';
  static const String plans = 'toke.plans';
  static const String problemSupport = 'toke.problem_support';
}

const _appGuidanceReply = AssistantQuickReply(
  label: 'Conhecer recursos do app',
  intent: _TokeIntents.appGuidance,
);

const _accountHelpReply = AssistantQuickReply(
  label: 'Ajuda com minha conta',
  intent: _TokeIntents.accountHelp,
);

const _plansReply = AssistantQuickReply(
  label: 'Planos e assinatura',
  intent: _TokeIntents.plans,
);

const _problemSupportReply = AssistantQuickReply(
  label: 'Resolver um problema',
  intent: _TokeIntents.problemSupport,
);

/// Concierge digital de orientação e suporte do CareHub+.
class TokeAssistantRepository implements AssistantRepository {
  static const Duration _openingDelay = Duration(milliseconds: 300);
  static const Duration _replyDelay = Duration(milliseconds: 800);

  @override
  Future<List<AssistantMessage>> fetchInitialMessages() async {
    await Future<void>.delayed(_openingDelay);

    return [
      AssistantMessage.fromAssistant(
        id: _newMessageId(),
        text:
            'Olá! Eu sou o Toke, concierge digital do CareHub+. Estou aqui '
            'para oferecer um atendimento personalizado. Como posso ajudar?',
        timestamp: DateTime.now(),
        quickReplies: const [
          _appGuidanceReply,
          _accountHelpReply,
          _plansReply,
          _problemSupportReply,
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

    return _answerFor(intent ?? _intentFromText(text));
  }

  String _intentFromText(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('recurso') ||
        normalized.contains('aplicativo') ||
        normalized.contains('app')) {
      return _TokeIntents.appGuidance;
    }
    if (normalized.contains('conta') ||
        normalized.contains('perfil') ||
        normalized.contains('senha')) {
      return _TokeIntents.accountHelp;
    }
    if (normalized.contains('plano') ||
        normalized.contains('assinatura') ||
        normalized.contains('pagamento')) {
      return _TokeIntents.plans;
    }
    if (normalized.contains('problema') ||
        normalized.contains('erro') ||
        normalized.contains('ajuda')) {
      return _TokeIntents.problemSupport;
    }
    return _unknownIntent;
  }

  AssistantMessage _answerFor(String intent) {
    final (text, quickReplies) = switch (intent) {
      _TokeIntents.appGuidance => (
        'Posso orientar você sobre tarefas, rede de apoio, conversas, SOS e '
            'perfis de cuidado. Diga qual recurso deseja conhecer.',
        const [_accountHelpReply, _problemSupportReply],
      ),
      _TokeIntents.accountHelp => (
        'Posso ajudar a localizar opções de perfil, notificações e '
            'preferências. Para sua segurança, nunca envie sua senha no chat.',
        const [_appGuidanceReply, _problemSupportReply],
      ),
      _TokeIntents.plans => (
        'Você pode consultar e comparar as opções disponíveis em '
            'Configurações > Planos. Se tiver uma dúvida específica, '
            'descreva o que precisa saber.',
        const [_accountHelpReply, _problemSupportReply],
      ),
      _TokeIntents.problemSupport => (
        'Conte o que aconteceu e em qual tela você estava. Com esses detalhes, '
            'posso indicar os próximos passos disponíveis no aplicativo.',
        const [_appGuidanceReply, _accountHelpReply],
      ),
      _ => (
        'Estou aqui para orientar sua experiência no CareHub+. Posso explicar '
            'recursos do app, ajudar com a conta, apresentar os planos ou '
            'entender um problema.',
        const [
          _appGuidanceReply,
          _accountHelpReply,
          _plansReply,
          _problemSupportReply,
        ],
      ),
    };

    return AssistantMessage.fromAssistant(
      id: _newMessageId(),
      text: text,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
    );
  }

  String _newMessageId() => 'toke_${DateTime.now().microsecondsSinceEpoch}';
}

const String _unknownIntent = 'toke.unknown';
