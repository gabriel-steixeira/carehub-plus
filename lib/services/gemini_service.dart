/*
 * CareHub Plus — Serviços / Integração com Gemini
 *
 * Centraliza chamadas à API REST estável do Gemini, com contexto de cuidado,
 * histórico curto da conversa e repetição controlada para falhas transitórias.
 *
 * Author: Vitoria Lana
 * Created on: 23/09/2026
 * Version: 2.1.0
 * Squad: CareHub Plus
 */

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/gemini_config.dart';

/// Personas disponíveis para conversas assistidas por IA.
enum AIPersona {
  cora('Cora'),
  toke('Toke');

  const AIPersona(this.displayName);

  /// Nome exibido em mensagens de erro e na transcrição enviada ao modelo.
  final String displayName;
}

/// Um turno anterior enviado ao Gemini para preservar o contexto da conversa.
class GeminiChatMessage {
  const GeminiChatMessage({required this.role, required this.text});

  final String role;
  final String text;
}

/// Erro conhecido da integração, sem expor chave ou resposta bruta da API.
class GeminiServiceException implements Exception {
  const GeminiServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isTemporary =>
      statusCode == null ||
      statusCode == 429 ||
      (statusCode! >= 500 && statusCode! <= 504);

  @override
  String toString() => message;
}

/// Intenção que a Cora identificou na mensagem do cuidador.
enum CareIntentKind { conversation, createTaskProposal, createChatProposal }

/// Resultado estruturado da interpretação de uma mensagem.
///
/// Para conversa simples, apenas [reply] é usado. Quando a mensagem pede
/// criar uma tarefa ou um assunto de chat, os campos correspondentes vêm
/// preenchidos e [reply] traz a pergunta de confirmação sugerida pelo modelo.
class CareIntentResult {
  const CareIntentResult({
    required this.kind,
    required this.reply,
    this.taskTitle,
    this.taskDateTimeIso,
    this.taskFrequency,
    this.chatTitle,
    this.categoryId,
  });

  final CareIntentKind kind;
  final String reply;
  final String? taskTitle;
  final String? taskDateTimeIso;
  final String? taskFrequency;
  final String? chatTitle;

  /// Id de categoria escolhido pelo modelo entre as categorias disponíveis.
  final String? categoryId;

  bool get hasValidTaskProposal =>
      kind == CareIntentKind.createTaskProposal &&
      (taskTitle?.trim().isNotEmpty ?? false) &&
      (taskDateTimeIso?.trim().isNotEmpty ?? false);

  bool get hasValidChatProposal =>
      kind == CareIntentKind.createChatProposal &&
      (chatTitle?.trim().isNotEmpty ?? false);
}

/// Intenção que o Toke identificou na mensagem do cuidador (triagem).
enum SupportIntentKind {
  /// Dúvida resolvida só com conversa (navegação, conta, planos).
  conversation,

  /// Comparar valores de um plano sem contratar nada.
  simulatePlan,

  /// Pedido para trocar de plano; exige confirmação antes de gravar.
  contractPlan,

  /// Pix, fatura ou cartão: dependem de um gateway de pagamento.
  payment,

  /// Pedido explícito de atendimento humano.
  humanHandoff,
}

/// Resultado estruturado da triagem feita pelo Toke.
class SupportIntentResult {
  const SupportIntentResult({
    required this.kind,
    required this.reply,
    this.planId,
    this.billingCycle,
    this.paymentType,
    this.summary,
  });

  final SupportIntentKind kind;
  final String reply;

  /// Id do plano do catálogo, em simulação ou contratação.
  final String? planId;

  /// `monthly` ou `annual`, quando o cuidador indicar o ciclo.
  final String? billingCycle;

  /// `pix`, `fatura` ou `cartao`, quando [kind] for [SupportIntentKind.payment].
  final String? paymentType;

  /// Resumo do problema, usado para passar o caso a um humano sem repetição.
  final String? summary;
}

/// Cliente da Gemini Developer API usado pelas assistentes do CareHub Plus.
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _interactionsUrl =
      'https://generativelanguage.googleapis.com/v1beta/interactions';
  static const int _historyLimit = 10;

  final http.Client _client;

  /// Envia a mensagem atual com persona, dados do assistido e histórico curto.
  Future<String> sendMessage({
    required String userMessage,
    required AIPersona persona,
    Map<String, dynamic>? context,
    List<GeminiChatMessage> conversationHistory = const [],
  }) async {
    final message = userMessage.trim();
    if (message.isEmpty) {
      throw const GeminiServiceException('A mensagem não pode estar vazia.');
    }
    _ensureConfigured(persona);

    final payload = <String, dynamic>{
      'model': GeminiConfig.modelName,
      'system_instruction': _buildSystemPrompt(persona, context),
      'input': _buildInput(message, conversationHistory, persona: persona),
      'store': false,
      'generation_config': {'temperature': 0.4, 'thinking_level': 'minimal'},
    };

    final responseBody = await _postWithRetry(payload, persona: persona);
    return _extractText(responseBody, persona: persona);
  }

  /// Triagem do Toke ("No Wrong Door"): decide se a mensagem se resolve em
  /// conversa, em uma simulação/contratação de plano, em um pedido de
  /// pagamento ou se precisa ir para um humano. A resposta vem em JSON para que
  /// o app, e não o modelo, execute qualquer ação.
  Future<SupportIntentResult> interpretSupportRequest({
    required String userMessage,
    Map<String, dynamic>? context,
    List<GeminiChatMessage> conversationHistory = const [],
    List<String> availablePlanIds = const [],
  }) async {
    final message = userMessage.trim();
    if (message.isEmpty) {
      throw const GeminiServiceException('A mensagem não pode estar vazia.');
    }
    _ensureConfigured(AIPersona.toke);

    final payload = <String, dynamic>{
      'model': GeminiConfig.modelName,
      'system_instruction': _buildSupportPrompt(context),
      'input': _buildInput(
        message,
        conversationHistory,
        persona: AIPersona.toke,
      ),
      'store': false,
      'generation_config': {'temperature': 0.2, 'thinking_level': 'minimal'},
      'response_format': {
        'type': 'text',
        'mime_type': 'application/json',
        'schema': {
          'type': 'object',
          'properties': {
            'acao': {
              'type': 'string',
              'enum': [
                'conversar',
                'simular_plano',
                'contratar_plano',
                'pagamento',
                'transferir_humano',
              ],
              'description':
                  'simular_plano: quer saber quanto custa ou comparar um '
                  'plano. contratar_plano: pede para assinar, trocar ou fazer '
                  'upgrade. pagamento: Pix, boleto, fatura, cartão ou cobrança '
                  'recusada. transferir_humano: pede falar com uma pessoa ou o '
                  'problema não pode ser resolvido pelo app. Senão, conversar.',
            },
            'resposta': {
              'type': 'string',
              'description': 'Mensagem em português para o cuidador.',
            },
            'plano_id': {
              'type': 'string',
              if (availablePlanIds.isNotEmpty) 'enum': availablePlanIds,
              'description':
                  'Id do plano do catálogo, para simular_plano ou '
                  'contratar_plano.',
            },
            'ciclo': {
              'type': 'string',
              'enum': ['monthly', 'annual'],
              'description': 'Ciclo de cobrança, se o cuidador indicar.',
            },
            'tipo_pagamento': {
              'type': 'string',
              'enum': ['pix', 'fatura', 'cartao'],
              'description': 'Tipo do pedido, quando acao for pagamento.',
            },
            'resumo': {
              'type': 'string',
              'description':
                  'Resumo objetivo do problema em uma frase, quando acao for '
                  'transferir_humano ou pagamento.',
            },
          },
          'required': ['acao', 'resposta'],
        },
      },
    };

    final responseBody = await _postWithRetry(payload, persona: AIPersona.toke);
    return _parseSupportIntent(
      _extractText(responseBody, persona: AIPersona.toke),
    );
  }

  void _ensureConfigured(AIPersona persona) {
    if (GeminiConfig.apiKey.trim().isEmpty) {
      throw GeminiServiceException(
        'A integração com ${_article(persona)} ${persona.displayName} ainda '
        'não foi configurada.',
      );
    }
  }

  /// Artigo definido do nome da persona ("a Cora", "o Toke").
  String _article(AIPersona persona) => switch (persona) {
    AIPersona.cora => 'a',
    AIPersona.toke => 'o',
  };

  /// Interpreta a mensagem da cuidadora e decide entre conversar ou propor
  /// uma tarefa. Usa saída estruturada (JSON) para tornar a extração confiável.
  Future<CareIntentResult> interpretCareRequest({
    required String userMessage,
    Map<String, dynamic>? context,
    List<GeminiChatMessage> conversationHistory = const [],
    Map<String, String> availableCategories = const {},
  }) async {
    final message = userMessage.trim();
    if (message.isEmpty) {
      throw const GeminiServiceException('A mensagem não pode estar vazia.');
    }
    _ensureConfigured(AIPersona.cora);

    final categoryIds = availableCategories.keys.toList();

    final payload = <String, dynamic>{
      'model': GeminiConfig.modelName,
      'system_instruction': _buildStructuredPrompt(
        context,
        availableCategories,
      ),
      'input': _buildInput(
        message,
        conversationHistory,
        persona: AIPersona.cora,
      ),
      'store': false,
      'generation_config': {'temperature': 0.2, 'thinking_level': 'minimal'},
      'response_format': {
        'type': 'text',
        'mime_type': 'application/json',
        'schema': {
          'type': 'object',
          'properties': {
            'acao': {
              'type': 'string',
              'enum': ['conversar', 'criar_tarefa', 'criar_chat'],
              'description':
                  'Use criar_tarefa quando o cuidador pedir para agendar, '
                  'lembrar ou cadastrar algo com horário. Use criar_chat '
                  'quando pedir para abrir um assunto, conversa ou tópico '
                  'com a rede de apoio. Caso contrário, use conversar.',
            },
            'resposta': {
              'type': 'string',
              'description':
                  'Mensagem em português para o cuidador. Se acao for '
                  'criar_tarefa ou criar_chat, peça confirmação resumindo.',
            },
            'titulo': {
              'type': 'string',
              'description':
                  'Título curto da tarefa, quando acao for criar_tarefa.',
            },
            'data_hora': {
              'type': 'string',
              'description':
                  'Data e hora da tarefa em ISO 8601 no fuso local, '
                  'quando acao for criar_tarefa.',
            },
            'frequencia': {
              'type': 'string',
              'enum': ['once', 'daily', 'weekly'],
              'description':
                  'Recorrência da tarefa, quando acao for criar_tarefa.',
            },
            'titulo_chat': {
              'type': 'string',
              'description':
                  'Título curto do assunto, quando acao for criar_chat.',
            },
            'categoria': {
              'type': 'string',
              if (categoryIds.isNotEmpty) 'enum': categoryIds,
              'description':
                  'Id da categoria que melhor descreve a tarefa ou o assunto. '
                  'Escolha entre as categorias disponíveis no prompt.',
            },
          },
          'required': ['acao', 'resposta'],
        },
      },
    };

    final responseBody = await _postWithRetry(payload, persona: AIPersona.cora);
    return _parseCareIntent(
      _extractText(responseBody, persona: AIPersona.cora),
    );
  }

  Future<String> _postWithRetry(
    Map<String, dynamic> payload, {
    required AIPersona persona,
  }) async {
    final name = persona.displayName;
    final uri = Uri.parse(_interactionsUrl);
    final body = jsonEncode(payload);

    GeminiServiceException? lastError;
    for (var attempt = 0; attempt < GeminiConfig.maxRetries; attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': GeminiConfig.apiKey,
              },
              body: body,
            )
            .timeout(Duration(seconds: GeminiConfig.timeoutSeconds));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.body;
        }

        lastError = _exceptionFromResponse(response, persona: persona);
        if (!lastError.isTemporary || attempt == GeminiConfig.maxRetries - 1) {
          throw lastError;
        }
      } on TimeoutException {
        lastError = const GeminiServiceException(
          'O Gemini demorou para responder. Tente novamente.',
        );
        if (attempt == GeminiConfig.maxRetries - 1) {
          throw lastError;
        }
      } on http.ClientException {
        lastError = GeminiServiceException(
          'Não foi possível conectar ${_contraction(persona)} $name. '
          'Verifique sua internet.',
        );
        if (attempt == GeminiConfig.maxRetries - 1) {
          throw lastError;
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
    }

    throw lastError ??
        GeminiServiceException(
          'Não foi possível consultar ${_article(persona)} $name.',
        );
  }

  /// Contração de "a/o" com o nome da persona ("à Cora", "ao Toke").
  String _contraction(AIPersona persona) => switch (persona) {
    AIPersona.cora => 'à',
    AIPersona.toke => 'ao',
  };

  SupportIntentResult _parseSupportIntent(String rawText) {
    try {
      final decoded = jsonDecode(rawText) as Map<String, dynamic>;
      String? field(String key) {
        final value = (decoded[key] as String?)?.trim();
        return value == null || value.isEmpty ? null : value;
      }

      final kind = switch (field('acao')) {
        'simular_plano' => SupportIntentKind.simulatePlan,
        'contratar_plano' => SupportIntentKind.contractPlan,
        'pagamento' => SupportIntentKind.payment,
        'transferir_humano' => SupportIntentKind.humanHandoff,
        _ => SupportIntentKind.conversation,
      };

      return SupportIntentResult(
        kind: kind,
        reply:
            field('resposta') ??
            'Desculpe, não consegui entender. Pode reformular?',
        planId: field('plano_id'),
        billingCycle: field('ciclo'),
        paymentType: field('tipo_pagamento'),
        summary: field('resumo'),
      );
    } on FormatException {
      // Sem JSON válido, a resposta é tratada como conversa simples.
      return SupportIntentResult(
        kind: SupportIntentKind.conversation,
        reply: rawText.trim(),
      );
    }
  }

  CareIntentResult _parseCareIntent(String rawText) {
    try {
      final decoded = jsonDecode(rawText) as Map<String, dynamic>;
      final acao = decoded['acao'] as String?;
      final resposta = (decoded['resposta'] as String?)?.trim() ?? '';
      final categoryId = (decoded['categoria'] as String?)?.trim();

      if (acao == 'criar_tarefa') {
        return CareIntentResult(
          kind: CareIntentKind.createTaskProposal,
          reply: resposta.isEmpty
              ? 'Quer que eu registre essa tarefa?'
              : resposta,
          taskTitle: (decoded['titulo'] as String?)?.trim(),
          taskDateTimeIso: (decoded['data_hora'] as String?)?.trim(),
          taskFrequency: (decoded['frequencia'] as String?)?.trim(),
          categoryId: categoryId,
        );
      }

      if (acao == 'criar_chat') {
        return CareIntentResult(
          kind: CareIntentKind.createChatProposal,
          reply: resposta.isEmpty ? 'Quer que eu abra esse assunto?' : resposta,
          chatTitle: (decoded['titulo_chat'] as String?)?.trim(),
          categoryId: categoryId,
        );
      }

      return CareIntentResult(
        kind: CareIntentKind.conversation,
        reply: resposta.isEmpty
            ? 'Desculpe, não consegui entender. Pode reformular?'
            : resposta,
      );
    } on FormatException {
      // Se o modelo não devolver JSON válido, trata como conversa.
      return CareIntentResult(
        kind: CareIntentKind.conversation,
        reply: rawText.trim(),
      );
    }
  }

  String _buildInput(
    String currentMessage,
    List<GeminiChatMessage> conversationHistory, {
    required AIPersona persona,
  }) {
    final recentHistory = conversationHistory
        .where((item) => item.text.trim().isNotEmpty)
        .toList()
        .reversed
        .take(_historyLimit)
        .toList()
        .reversed;

    if (recentHistory.isEmpty) return currentMessage;

    final transcript = recentHistory
        .map((item) {
          final author = item.role == 'model'
              ? persona.displayName
              : 'Cuidador';
          return '$author: ${item.text.trim()}';
        })
        .join('\n');

    return '''
Conversa anterior:
$transcript

Mensagem atual do cuidador:
$currentMessage
''';
  }

  String _extractText(String responseBody, {required AIPersona persona}) {
    final noAnswerError = GeminiServiceException(
      '${_article(persona).toUpperCase()} ${persona.displayName} não '
      'conseguiu formular uma resposta segura.',
    );
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final steps = decoded['steps'] as List<dynamic>?;
    if (steps == null || steps.isEmpty) {
      throw noAnswerError;
    }

    final text = steps
        .whereType<Map<String, dynamic>>()
        .where((step) => step['type'] == 'model_output')
        .expand((step) => step['content'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((content) => content['type'] == 'text')
        .map((content) => content['text'])
        .whereType<String>()
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw noAnswerError;
    }
    return text;
  }

  GeminiServiceException _exceptionFromResponse(
    http.Response response, {
    required AIPersona persona,
  }) {
    // "a Cora" / "o Toke", com as contrações usadas nas frases abaixo.
    final withArticle = '${_article(persona)} ${persona.displayName}';
    final withContraction = '${_contraction(persona)} ${persona.displayName}';
    final subject = '${_article(persona).toUpperCase()} ${persona.displayName}';
    final ofPersona = persona == AIPersona.cora
        ? 'da ${persona.displayName}'
        : 'do ${persona.displayName}';
    final forPersona = persona == AIPersona.cora
        ? 'para a ${persona.displayName}'
        : 'para o ${persona.displayName}';

    final message = switch (response.statusCode) {
      400 => 'A solicitação enviada $withContraction não foi aceita.',
      401 || 403 => 'A integração com $withArticle não está autorizada.',
      404 => 'O modelo configurado $forPersona não está disponível.',
      429 => '$subject recebeu muitas solicitações. Aguarde um momento.',
      >= 500 && <= 504 =>
        'O serviço $ofPersona está temporariamente indisponível.',
      _ => 'Não foi possível consultar $withArticle.',
    };

    return GeminiServiceException(message, statusCode: response.statusCode);
  }

  String _buildSystemPrompt(AIPersona persona, Map<String, dynamic>? context) {
    final formattedContext = _formatContext(context ?? const {});

    return switch (persona) {
      AIPersona.cora =>
        '''
Você é a Cora, assistente de cuidado e rotina do CareHub Plus.
Converse em português do Brasil com acolhimento, clareza e objetividade.

Seu papel:
- explicar somente rotinas, tarefas e informações presentes no contexto;
- ajudar a organizar o cuidado de idosos, crianças e pets;
- apontar possíveis inconsistências sem alarmismo;
- sugerir próximos passos dentro do aplicativo.

Limites obrigatórios:
- nunca invente cadastro, horário, dosagem, condição clínica ou tarefa;
- se o dado não estiver no contexto, diga claramente que ele não está disponível;
- não diagnostique, não prescreva e não altere orientação profissional;
- em possível emergência, oriente a buscar atendimento e usar o SOS do app;
- você ainda não executa ações: não afirme que criou tarefa, enviou mensagem ou acionou alguém;
- respostas simples devem ter de duas a quatro frases.

Data e hora local: ${DateTime.now().toIso8601String()}
Contexto autorizado do assistido selecionado:
$formattedContext
''',
      AIPersona.toke =>
        '''
${_tokeIdentity()}

Contexto da conta (Context Token):
${_formatSupportContext(context ?? const {})}
''',
    };
  }

  /// Identidade, mapa do app e limites do Toke, comuns à conversa simples e à
  /// triagem estruturada.
  String _tokeIdentity() => '''
Você é o Toke Concierge, central de atendimento e suporte do CareHub Plus.
Converse em português do Brasil de forma cordial, profissional e objetiva.

Seu papel (Customer Success):
- atender sem repetição: use o contexto da conta abaixo e nunca peça ao
  cuidador dados que já estão nele;
- se houver pendência no contexto, comece pelo diagnóstico e pela solução;
- orientar navegação, conta, planos e assinatura;
- fazer a triagem: resolver no chat, acionar uma ação do app ou encaminhar a um
  atendente humano com o caso resumido.

Mapa do aplicativo:
- barra inferior: Início, Tarefas, Cora (assistente de cuidado), Chat e SOS;
- Configurações: Rede de Apoio, Notificações, Fale conosco (Toke), Preferências
  (em breve), Planos e Sobre;
- Perfil: editar nome, telefone, data de nascimento e foto;
- dúvidas de cuidado, rotina, remédios ou tarefas são com a Cora; em emergência,
  oriente o botão SOS.

Limites obrigatórios:
- nunca invente preço, plano, cobrança, fatura, prazo ou status da conta; use
  somente o contexto; se o dado não existir, diga que não está disponível;
- o app ainda não tem gateway de pagamento: você não gera Pix, boleto ou
  fatura e não altera cartão;
- nunca afirme que executou uma ação; quem executa é o app, após confirmação;
- nunca peça senha, número completo de cartão ou código de segurança;
- respostas simples devem ter de duas a quatro frases.

Data e hora local: ${DateTime.now().toIso8601String()}''';

  String _buildSupportPrompt(Map<String, dynamic>? context) {
    return '''
${_tokeIdentity()}

Analise a mensagem do cuidador e responda SEMPRE no formato JSON solicitado.

Como decidir a ação:
- "simular_plano": quer saber preço, comparar planos ou quanto economiza no
  anual. Preencha "plano_id" com um id do catálogo e "ciclo" se ele indicar;
- "contratar_plano": pede para assinar, trocar ou fazer upgrade de plano.
  Preencha "plano_id" e "ciclo" (use "monthly" se ele não disser). Em
  "resposta", NUNCA diga que contratou: apenas resuma e peça confirmação;
- "pagamento": pede Pix, boleto, segunda via, fatura, trocar cartão ou relata
  cobrança recusada. Preencha "tipo_pagamento" e "resumo";
- "transferir_humano": pede falar com uma pessoa, está insatisfeito ou o
  problema não se resolve pelo app. Preencha "resumo";
- em qualquer outro caso use "conversar".

Contexto da conta (Context Token):
${_formatSupportContext(context ?? const {})}
''';
  }

  /// Formata o contexto da conta para o Toke, sem expor ids internos.
  String _formatSupportContext(Map<String, dynamic> context) {
    if (context['contextAvailable'] == false) {
      return 'Os dados da conta não puderam ser consultados agora.';
    }

    final lines = <String>[];
    void addValue(String label, String key) {
      final value = context[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        lines.add('$label: $value');
      }
    }

    addValue('Cuidador', 'userName');
    addValue('Plano atual', 'currentPlan');
    addValue('Contrato', 'subscription');
    addValue('Pendências detectadas', 'pendencies');
    addValue(
      'Catálogo de planos (id | nome | mensal | anual | benefícios)',
      'catalog',
    );

    return lines.isEmpty
        ? 'Nenhuma informação da conta foi disponibilizada.'
        : lines.join('\n');
  }

  String _buildStructuredPrompt(
    Map<String, dynamic>? context, [
    Map<String, String> availableCategories = const {},
  ]) {
    final formattedContext = _formatContext(context ?? const {});
    final categoriesBlock = availableCategories.isEmpty
        ? 'Nenhuma categoria disponível; deixe "categoria" vazio.'
        : availableCategories.entries
              .map((entry) => '- ${entry.key}: ${entry.value}')
              .join('\n');

    return '''
Você é a Cora, assistente de cuidado e rotina do CareHub Plus.
Analise a mensagem do cuidador e responda SEMPRE no formato JSON solicitado.

Como decidir a ação:
- use "criar_tarefa" quando o cuidador pedir para agendar, lembrar, marcar ou
  cadastrar algo com horário (ex.: "cria um lembrete", "marca a consulta");
- use "criar_chat" quando pedir para abrir um assunto, conversa ou tópico com a
  rede de apoio (ex.: "abre um assunto sobre a consulta", "cria uma conversa
  sobre a medicação");
- em qualquer outro caso use "conversar".

Regras para "criar_tarefa":
- "titulo": curto e claro, em português (ex.: "Dar ração", "Remédio de pressão");
- "data_hora": ISO 8601 no fuso local; se o cuidador não indicar o dia, use hoje;
  se não indicar hora, use 09:00; nunca invente datas passadas;
- "frequencia": "once" (padrão), "daily" ou "weekly";
- "resposta": NUNCA diga que a tarefa foi criada, registrada ou salva. Apenas
  resuma o que será agendado e pergunte se pode registrar. Exemplo:
  "Quer que eu registre 'Dar ração' hoje às 18:00?".

Regras para "criar_chat":
- "titulo_chat": curto e claro, em português (ex.: "Consulta cardiologista",
  "Troca de medicação");
- "resposta": NUNCA diga que o assunto foi criado ou aberto. Apenas resuma e
  pergunte se pode abrir. Exemplo: "Quer que eu abra o assunto 'Consulta'?".

Regra de categoria (para criar_tarefa e criar_chat):
- Preencha "categoria" com o id da categoria que melhor descreve o item,
  escolhendo APENAS entre as categorias disponíveis abaixo.
- Se nenhuma encaixar bem, use "other".

Categorias disponíveis (id: rótulo):
$categoriesBlock

Regras para "conversar":
- responda em português, com acolhimento e objetividade;
- baseie-se somente no contexto; se o dado não existir, diga que não está
  disponível; não diagnostique nem prescreva; em emergência, oriente o SOS.

Data e hora local: ${DateTime.now().toIso8601String()}
Contexto autorizado do assistido selecionado:
$formattedContext
''';
  }

  String _formatContext(Map<String, dynamic> context) {
    if (context['contextAvailable'] == false) {
      return 'Os dados cadastrados não puderam ser consultados agora.';
    }

    final lines = <String>[];
    void addValue(String label, String key) {
      final value = context[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        lines.add('$label: $value');
      }
    }

    addValue('Nome', 'careRecipientName');
    addValue('Tipo', 'careRecipientType');
    addValue('Data de nascimento', 'dateOfBirth');
    addValue('Tarefas cadastradas', 'tasks');
    addValue('Observações cadastradas', 'notes');
    addValue('Cuidador', 'userName');

    return lines.isEmpty
        ? 'Nenhuma informação do assistido foi disponibilizada.'
        : lines.join('\n');
  }

  /// Faz uma chamada mínima para validar modelo, chave e conectividade.
  Future<bool> testConnection() async {
    final response = await sendMessage(
      userMessage: 'Responda somente OK.',
      persona: AIPersona.cora,
    );
    return response.trim().isNotEmpty;
  }
}
