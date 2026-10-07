/*
 * CareHub Plus — Dados / Conversa com a Cora
 *
 * O cérebro da Cora vive no backend (função `coraChat`), o mesmo usado pelo
 * WhatsApp: lá ficam a chave do Gemini, a conferência de acesso ao
 * assistido, o histórico e o rascunho de tarefa aguardando confirmação.
 * Aqui sobra só o que é do app: a saudação, o perfil selecionado, as
 * categorias guardadas no aparelho e a conversão da resposta em mensagens.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 3.0.0
 * Squad: CareHub Plus
 */

import '../../../../core/errors/app_exception.dart';
import '../../../../services/cloud_functions_service.dart';
import '../../../../services/selected_profile_service.dart';
import '../../../categories/data/repositories/care_categories_repository.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

abstract final class _CoraIntents {
  static const String careRecipientSummary = 'cora.care_recipient_summary';
  static const String routine = 'cora.routine';
  static const String tasks = 'cora.tasks';
  static const String careTips = 'cora.care_tips';
}

const _careRecipientReply = AssistantQuickReply(
  label: 'Resumo do assistido',
  intent: _CoraIntents.careRecipientSummary,
);

const _routineReply = AssistantQuickReply(
  label: 'Rotina do assistido',
  intent: _CoraIntents.routine,
);

const _tasksReply = AssistantQuickReply(
  label: 'Próximas tarefas',
  intent: _CoraIntents.tasks,
);

const _careTipsReply = AssistantQuickReply(
  label: 'Dicas de cuidado',
  intent: _CoraIntents.careTips,
);

/// Cora — assistente proativa de cuidados do CareHub Plus.
class CoraAssistantRepository implements AssistantRepository {
  CoraAssistantRepository({
    CallableClient? client,
    CareCategoriesRepository? categoriesRepository,
    Future<SelectedProfileService> Function()? profileServiceFactory,
    String? sessionId,
  }) : _client = client ?? CloudFunctionsService(),
       _categoriesRepository =
           categoriesRepository ?? CareCategoriesRepository(),
       _profileServiceFactory =
           profileServiceFactory ?? SelectedProfileService.create,
       // Uma conversa nova a cada abertura da tela: o backend descarta o
       // histórico e o rascunho de uma sessão anterior.
       _sessionId =
           sessionId ?? 'app_${DateTime.now().microsecondsSinceEpoch}';

  static const String _function = 'coraChat';
  static const Duration _openingDelay = Duration(milliseconds: 300);

  final CallableClient _client;
  final CareCategoriesRepository _categoriesRepository;
  final Future<SelectedProfileService> Function() _profileServiceFactory;
  final String _sessionId;
  SelectedProfileService? _profileService;

  /// Cache das categorias (id → rótulo) durante a conversa.
  Map<String, String>? _categoriesCache;

  Future<SelectedProfileService> _profiles() async =>
      _profileService ??= await _profileServiceFactory();

  /// Categorias da cuidadora (guardadas no aparelho). Em falha, o backend usa
  /// as categorias padrão.
  Future<Map<String, String>> _loadCategories() async {
    final cached = _categoriesCache;
    if (cached != null) return cached;
    try {
      final categories = await _categoriesRepository.fetchCategories();
      return _categoriesCache = {for (final c in categories) c.id: c.label};
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<List<AssistantMessage>> fetchInitialMessages() async {
    final profiles = await _profiles();
    await Future<void>.delayed(_openingDelay);

    final careRecipientName = profiles.getSelectedProfileName();
    final greeting = careRecipientName == null
        ? 'Olá! Eu sou a Cora. Selecione um perfil para eu consultar a rotina '
              'de cuidado correta.'
        : 'Olá! Eu sou a Cora. Como posso ajudar nos cuidados de '
              '$careRecipientName hoje?';

    return [
      AssistantMessage.fromAssistant(
        id: _newMessageId(),
        text: greeting,
        timestamp: DateTime.now(),
        quickReplies: const [
          _careRecipientReply,
          _routineReply,
          _tasksReply,
          _careTipsReply,
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
    final careRecipientId = (await _profiles()).getSelectedProfileId();
    if (careRecipientId == null || careRecipientId.isEmpty) {
      return _assistantMessage(
        'Selecione primeiro o perfil da pessoa ou do pet que será cuidado. '
        'Assim eu uso somente os dados corretos.',
        quickReplies: const [],
      );
    }

    try {
      final categories = await _loadCategories();
      final data = await _client.call(_function, {
        'careRecipientId': careRecipientId,
        'sessionId': _sessionId,
        'text': text,
        'intent': ?intent,
        if (categories.isNotEmpty) 'categories': categories,
      });
      return _assistantMessage(
        (data['text'] as String?)?.trim().isNotEmpty == true
            ? data['text'] as String
            : 'Desculpe, não consegui entender. Pode reformular?',
        quickReplies: _readQuickReplies(data['quickReplies']),
      );
    } on AppException catch (error) {
      final message = error.code == 'permission-denied'
          ? 'Você não tem acesso a este perfil. Selecione outro perfil para '
                'continuar.'
          : error.message;
      return _assistantMessage(
        message,
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }
  }

  List<AssistantQuickReply> _readQuickReplies(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final label = item['label'];
          final intent = item['intent'];
          return label is String && intent is String
              ? AssistantQuickReply(label: label, intent: intent)
              : null;
        })
        .whereType<AssistantQuickReply>()
        .toList();
  }

  AssistantMessage _assistantMessage(
    String text, {
    required List<AssistantQuickReply> quickReplies,
  }) {
    return AssistantMessage.fromAssistant(
      id: _newMessageId(),
      text: text,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
    );
  }

  String _newMessageId() => 'cora_${DateTime.now().microsecondsSinceEpoch}';
}
