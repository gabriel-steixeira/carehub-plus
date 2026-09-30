/*
 * CareHub Plus — Dados / Cérebro da Cora
 *
 * Implementa a Cora com contexto do assistido selecionado, tarefas reais do
 * Firestore e histórico curto da conversa, sem colocar regras na interface.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 2.1.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../services/gemini_service.dart';
import '../../../../services/selected_profile_service.dart';
import '../../../categories/data/repositories/care_categories_repository.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../tasks/data/models/task_frequency.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

abstract final class _CoraIntents {
  static const String careRecipientSummary = 'cora.care_recipient_summary';
  static const String routine = 'cora.routine';
  static const String tasks = 'cora.tasks';
  static const String careTips = 'cora.care_tips';
  static const String confirmTask = 'cora.task.create.confirm';
  static const String cancelTask = 'cora.task.create.cancel';
  static const String confirmChat = 'cora.chat.create.confirm';
  static const String cancelChat = 'cora.chat.create.cancel';
}

/// Categoria padrão de um assunto criado pela Cora (igual ao default do modelo).
const String _defaultChatCategoryId = 'health';

/// Categoria padrão de uma tarefa criada pela Cora (igual ao default do modelo).
const String _defaultTaskCategoryId = 'other';

/// Rascunho de tarefa proposto pela Cora e ainda não confirmado.
class _TaskDraft {
  const _TaskDraft({
    required this.careRecipientId,
    required this.title,
    required this.scheduledTime,
    required this.frequency,
    required this.categoryId,
  });

  final String careRecipientId;
  final String title;
  final DateTime scheduledTime;
  final TaskFrequency frequency;
  final String categoryId;
}

/// Rascunho de assunto de chat proposto pela Cora e ainda não confirmado.
class _ChatDraft {
  const _ChatDraft({
    required this.careRecipientId,
    required this.careRecipientName,
    required this.title,
    required this.categoryId,
  });

  final String careRecipientId;
  final String careRecipientName;
  final String title;
  final String categoryId;
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

const _confirmTaskReply = AssistantQuickReply(
  label: '✅ Confirmar tarefa',
  intent: _CoraIntents.confirmTask,
);

const _cancelTaskReply = AssistantQuickReply(
  label: 'Cancelar',
  intent: _CoraIntents.cancelTask,
);

const _confirmChatReply = AssistantQuickReply(
  label: '✅ Criar assunto',
  intent: _CoraIntents.confirmChat,
);

const _cancelChatReply = AssistantQuickReply(
  label: 'Cancelar',
  intent: _CoraIntents.cancelChat,
);

/// Cora — assistente proativa de cuidados do CareHub Plus.
class CoraAssistantRepository implements AssistantRepository {
  CoraAssistantRepository({
    GeminiService? geminiService,
    TasksRepository? tasksRepository,
    ChatRepository? chatRepository,
    CareCategoriesRepository? categoriesRepository,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _geminiService = geminiService ?? GeminiService(),
       _tasksRepository = tasksRepository ?? TasksRepository(),
       _chatRepository = chatRepository ?? ChatRepository(),
       _categoriesRepository =
           categoriesRepository ?? CareCategoriesRepository(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const Duration _openingDelay = Duration(milliseconds: 300);
  static const int _taskContextLimit = 8;

  final GeminiService _geminiService;
  final TasksRepository _tasksRepository;
  final ChatRepository _chatRepository;
  final CareCategoriesRepository _categoriesRepository;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  SelectedProfileService? _profileService;

  /// Cache das categorias disponíveis (id → rótulo) durante a conversa.
  Map<String, String>? _categoriesCache;

  /// Última tarefa proposta e aguardando confirmação do cuidador.
  _TaskDraft? _pendingTaskDraft;

  /// Último assunto de chat proposto e aguardando confirmação do cuidador.
  _ChatDraft? _pendingChatDraft;

  Future<void> _ensureProfileService() async {
    _profileService ??= await SelectedProfileService.create();
  }

  /// Carrega as categorias disponíveis (id → rótulo), com cache local.
  /// Em caso de falha, retorna vazio: o fluxo cai nos defaults seguros.
  Future<Map<String, String>> _loadCategories() async {
    final cached = _categoriesCache;
    if (cached != null) return cached;

    try {
      final categories = await _categoriesRepository.fetchCategories();
      final map = {for (final c in categories) c.id: c.label};
      _categoriesCache = map;
      return map;
    } catch (_) {
      return const {};
    }
  }

  /// Valida o id sugerido pelo modelo; se inválido, usa o fallback informado.
  String _resolveCategoryId(
    String? suggested,
    Map<String, String> categories,
    String fallback,
  ) {
    final id = suggested?.trim();
    if (id != null && id.isNotEmpty && categories.containsKey(id)) {
      return id;
    }
    return fallback;
  }

  @override
  Future<List<AssistantMessage>> fetchInitialMessages() async {
    await _ensureProfileService();
    await Future<void>.delayed(_openingDelay);

    final careRecipientName = _profileService?.getSelectedProfileName();
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
    await _ensureProfileService();

    // Confirmação/cancelamento de uma proposta não dependem do Gemini.
    if (intent == _CoraIntents.confirmTask) {
      return _confirmPendingTask();
    }
    if (intent == _CoraIntents.cancelTask) {
      _pendingTaskDraft = null;
      return _assistantMessage(
        'Tudo bem, não vou registrar essa tarefa. Posso ajudar em algo mais?',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }
    if (intent == _CoraIntents.confirmChat) {
      return _confirmPendingChat();
    }
    if (intent == _CoraIntents.cancelChat) {
      _pendingChatDraft = null;
      return _assistantMessage(
        'Tudo bem, não vou abrir esse assunto. Posso ajudar em algo mais?',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }

    final careRecipientId = _profileService?.getSelectedProfileId();
    if (careRecipientId == null || careRecipientId.isEmpty) {
      return _assistantMessage(
        'Selecione primeiro o perfil da pessoa ou do pet que será cuidado. '
        'Assim eu uso somente os dados corretos.',
        quickReplies: const [],
      );
    }

    try {
      final context = await _fetchCareRecipientContext(careRecipientId);
      final categories = await _loadCategories();
      final interpretation = await _geminiService.interpretCareRequest(
        userMessage: text,
        context: context,
        conversationHistory: _mapHistory(history, currentText: text),
        availableCategories: categories,
      );

      if (interpretation.kind == CareIntentKind.createTaskProposal) {
        return _handleTaskProposal(interpretation, careRecipientId, categories);
      }
      if (interpretation.kind == CareIntentKind.createChatProposal) {
        return _handleChatProposal(interpretation, careRecipientId, categories);
      }

      _pendingTaskDraft = null;
      _pendingChatDraft = null;
      return _assistantMessage(
        interpretation.reply,
        quickReplies: const [_careRecipientReply, _tasksReply, _careTipsReply],
      );
    } on GeminiServiceException catch (error) {
      return _assistantMessage(
        '${error.message} Você pode tentar novamente em instantes.',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    } catch (_) {
      return _assistantMessage(
        'Não consegui consultar a Cora agora. Tente novamente em instantes.',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }
  }

  /// Monta a proposta de tarefa e guarda o rascunho até a confirmação.
  AssistantMessage _handleTaskProposal(
    CareIntentResult interpretation,
    String careRecipientId,
    Map<String, String> categories,
  ) {
    final parsedTime = DateTime.tryParse(interpretation.taskDateTimeIso ?? '');

    if (!interpretation.hasValidTaskProposal || parsedTime == null) {
      _pendingTaskDraft = null;
      return _assistantMessage(
        'Entendi que você quer criar uma tarefa, mas preciso do título e do '
        'horário. Pode me dizer o que agendar e para quando?',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }

    // O modelo às vezes devolve uma data no passado (ex.: ano errado).
    // Reprojetamos o horário para hoje/amanhã mantendo hora e minuto.
    final scheduledTime = _ensureFutureDateTime(parsedTime);
    final categoryId = _resolveCategoryId(
      interpretation.categoryId,
      categories,
      _defaultTaskCategoryId,
    );

    final draft = _TaskDraft(
      careRecipientId: careRecipientId,
      title: interpretation.taskTitle!.trim(),
      scheduledTime: scheduledTime,
      frequency: TaskFrequency.fromValue(
        interpretation.taskFrequency ?? 'once',
      ),
      categoryId: categoryId,
    );
    _pendingTaskDraft = draft;
    _pendingChatDraft = null;

    // A pergunta de confirmação é montada no app com os dados já corrigidos,
    // para não depender do texto do modelo (que pode afirmar ter criado).
    final frequencyNote = draft.frequency == TaskFrequency.once
        ? ''
        : ' (${draft.frequency.label.toLowerCase()})';
    final categoryLabel = categories[categoryId];
    final categoryNote = categoryLabel == null
        ? ''
        : ' na categoria $categoryLabel';

    return _assistantMessage(
      'Quer que eu registre "${draft.title}" para '
      '${_formatDateTime(draft.scheduledTime)}$frequencyNote$categoryNote?',
      quickReplies: const [_confirmTaskReply, _cancelTaskReply],
    );
  }

  /// Cria de fato a tarefa confirmada, reutilizando o repositório de tarefas.
  Future<AssistantMessage> _confirmPendingTask() async {
    final draft = _pendingTaskDraft;
    if (draft == null) {
      return _assistantMessage(
        'Não há nenhuma tarefa aguardando confirmação. Quer criar uma nova?',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }

    try {
      await _tasksRepository.addTask(
        TaskModel(
          id: '',
          caregiverId: '', // Sobrescrito pelo repositório com o UID logado.
          careRecipientId: draft.careRecipientId,
          title: draft.title,
          scheduledTime: draft.scheduledTime,
          frequency: draft.frequency,
          categoryId: draft.categoryId,
        ),
      );
      _pendingTaskDraft = null;

      return _assistantMessage(
        '✅ Pronto! Registrei "${draft.title}" para '
        '${_formatDateTime(draft.scheduledTime)}. Ela aparece na aba Tarefas.',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    } catch (_) {
      return _assistantMessage(
        'Não consegui salvar a tarefa agora. Tente confirmar novamente em '
        'instantes ou cadastre pela aba Tarefas.',
        quickReplies: const [_confirmTaskReply, _cancelTaskReply],
      );
    }
  }

  /// Monta a proposta de assunto de chat e guarda o rascunho até a confirmação.
  AssistantMessage _handleChatProposal(
    CareIntentResult interpretation,
    String careRecipientId,
    Map<String, String> categories,
  ) {
    final careRecipientName =
        _profileService?.getSelectedProfileName() ?? 'o assistido';

    if (!interpretation.hasValidChatProposal) {
      _pendingChatDraft = null;
      return _assistantMessage(
        'Entendi que você quer abrir um assunto, mas preciso de um título. '
        'Sobre o que será a conversa?',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }

    final categoryId = _resolveCategoryId(
      interpretation.categoryId,
      categories,
      _defaultChatCategoryId,
    );

    final draft = _ChatDraft(
      careRecipientId: careRecipientId,
      careRecipientName: careRecipientName,
      title: interpretation.chatTitle!.trim(),
      categoryId: categoryId,
    );
    _pendingChatDraft = draft;
    _pendingTaskDraft = null;

    final categoryLabel = categories[categoryId];
    final categoryNote = categoryLabel == null
        ? ''
        : ' na categoria $categoryLabel';

    return _assistantMessage(
      'Quer que eu abra o assunto "${draft.title}" para '
      '${draft.careRecipientName}$categoryNote?',
      quickReplies: const [_confirmChatReply, _cancelChatReply],
    );
  }

  /// Cria de fato o assunto confirmado, reutilizando o repositório de chat.
  Future<AssistantMessage> _confirmPendingChat() async {
    final draft = _pendingChatDraft;
    if (draft == null) {
      return _assistantMessage(
        'Não há nenhum assunto aguardando confirmação. Quer criar um novo?',
        quickReplies: const [_tasksReply, _careRecipientReply],
      );
    }

    try {
      await _chatRepository.addRoom(
        careRecipientId: draft.careRecipientId,
        title: draft.title,
        careRecipientName: draft.careRecipientName,
        categoryId: draft.categoryId,
      );
      _pendingChatDraft = null;

      return _assistantMessage(
        '✅ Pronto! Abri o assunto "${draft.title}" para '
        '${draft.careRecipientName}. Ele aparece na aba Chat.',
        quickReplies: const [_careRecipientReply, _tasksReply],
      );
    } catch (_) {
      return _assistantMessage(
        'Não consegui abrir o assunto agora. Tente confirmar novamente em '
        'instantes ou crie pela aba Chat.',
        quickReplies: const [_confirmChatReply, _cancelChatReply],
      );
    }
  }

  /// Garante que o horário proposto esteja no futuro, preservando hora/minuto.
  /// Se a data já passou, usa hoje; se hoje já passou desse horário, amanhã.
  DateTime _ensureFutureDateTime(DateTime proposed) {
    final now = DateTime.now();
    if (proposed.isAfter(now)) return proposed;

    final todayAtTime = DateTime(
      now.year,
      now.month,
      now.day,
      proposed.hour,
      proposed.minute,
    );
    if (todayAtTime.isAfter(now)) return todayAtTime;
    return todayAtTime.add(const Duration(days: 1));
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date às $time';
  }

  Future<Map<String, dynamic>> _fetchCareRecipientContext(
    String careRecipientId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const {'contextAvailable': false};
    }

    try {
      final recipientDocument = await _firestore
          .collection('care_recipients')
          .doc(careRecipientId)
          .get();
      final recipientData = recipientDocument.data();

      if (recipientData == null || recipientData['caregiverId'] != user.uid) {
        return const {'contextAvailable': false};
      }

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('caregiverId', isEqualTo: user.uid)
          .where('careRecipientId', isEqualTo: careRecipientId)
          .get();
      final taskData = tasksSnapshot.docs.map((document) => document.data());
      final orderedTasks = taskData.toList()
        ..sort((left, right) {
          final leftDate = _taskDate(left);
          final rightDate = _taskDate(right);
          return leftDate.compareTo(rightDate);
        });

      final taskSummaries = orderedTasks
          .take(_taskContextLimit)
          .map(_taskSummary)
          .where((summary) => summary.isNotEmpty)
          .join('; ');

      return {
        'contextAvailable': true,
        'careRecipientName': recipientData['name'],
        'careRecipientType':
            recipientData['recipientType'] ?? recipientData['type'],
        'dateOfBirth': recipientData['dateOfBirth'],
        'tasks': taskSummaries.isEmpty
            ? 'Nenhuma tarefa cadastrada para este perfil.'
            : taskSummaries,
      };
    } on FirebaseException {
      return const {'contextAvailable': false};
    }
  }

  DateTime _taskDate(Map<String, dynamic> task) {
    final value = task['scheduledTime'];
    return value is String
        ? DateTime.tryParse(value) ?? DateTime(9999)
        : DateTime(9999);
  }

  String _taskSummary(Map<String, dynamic> task) {
    final title = task['title'] as String?;
    if (title == null || title.trim().isEmpty) return '';

    final scheduledTime = _taskDate(task);
    final status = task['isCompleted'] == true ? 'concluída' : 'pendente';
    if (scheduledTime.year == 9999) return '$title ($status)';

    final localTime = scheduledTime.toLocal();
    final date =
        '${localTime.day.toString().padLeft(2, '0')}/'
        '${localTime.month.toString().padLeft(2, '0')}/'
        '${localTime.year}';
    final time =
        '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}';
    return '$title em $date às $time ($status)';
  }

  List<GeminiChatMessage> _mapHistory(
    List<AssistantMessage> history, {
    required String currentText,
  }) {
    final previousMessages = List<AssistantMessage>.of(history);
    if (previousMessages.isNotEmpty &&
        previousMessages.last.isFromUser &&
        previousMessages.last.text.trim() == currentText.trim()) {
      previousMessages.removeLast();
    }

    while (previousMessages.isNotEmpty && !previousMessages.first.isFromUser) {
      previousMessages.removeAt(0);
    }

    return previousMessages
        .map(
          (message) => GeminiChatMessage(
            role: message.isFromUser ? 'user' : 'model',
            text: message.text,
          ),
        )
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
