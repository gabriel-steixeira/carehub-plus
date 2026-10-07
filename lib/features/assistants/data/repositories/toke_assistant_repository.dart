/*
 * CareHub Plus — Dados / Cérebro do Toke
 *
 * Implementa o Toke Concierge com IA (Gemini, chamado pelo backend na função
 * `tokeInterpret` — a chave não fica no app) e contexto real da conta: perfil,
 * plano atual, contrato e catálogo de planos. Faz a triagem "No Wrong Door":
 * responde, simula ou contrata planos (após confirmação), explica o que ainda
 * depende de gateway de pagamento e prepara o repasse para um humano.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 3.0.0
 * Squad: CareHub Plus
 */

import '../../../../core/errors/app_exception.dart';
import '../../../profile/data/repositories/caregiver_profile_repository.dart';
import '../../../subscriptions/data/repositories/subscriptions_repository.dart';
import '../../../subscriptions/domain/entities/contracted_subscription_entity.dart';
import '../../../subscriptions/domain/entities/subscription_plan_entity.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_quick_reply_entity.dart';
import '../../domain/entities/support_intent_entity.dart';
import '../../domain/repositories/assistant_repository.dart';
import 'toke_interpreter_client.dart';

/// Intenções estáveis dos atalhos do Toke.
abstract final class _TokeIntents {
  static const String appGuidance = 'toke.app_guidance';
  static const String plans = 'toke.plans';
  static const String payment = 'toke.payment';
  static const String human = 'toke.human';
  static const String confirmPlan = 'toke.plan.contract.confirm';
  static const String cancelPlan = 'toke.plan.contract.cancel';

  /// Prefixo de "propor contratação": `toke.plan.propose:<planId>:<ciclo>`.
  static const String proposePlanPrefix = 'toke.plan.propose:';
}

const _appGuidanceReply = AssistantQuickReply(
  label: 'Conhecer recursos do app',
  intent: _TokeIntents.appGuidance,
);

const _plansReply = AssistantQuickReply(
  label: 'Comparar planos',
  intent: _TokeIntents.plans,
);

const _paymentReply = AssistantQuickReply(
  label: 'Pagamento e fatura',
  intent: _TokeIntents.payment,
);

const _humanReply = AssistantQuickReply(
  label: 'Falar com um atendente',
  intent: _TokeIntents.human,
);

const _confirmPlanReply = AssistantQuickReply(
  label: '✅ Confirmar contratação',
  intent: _TokeIntents.confirmPlan,
);

const _cancelPlanReply = AssistantQuickReply(
  label: 'Cancelar',
  intent: _TokeIntents.cancelPlan,
);

const _defaultReplies = [_plansReply, _paymentReply, _humanReply];

/// Retrato da conta usado como "Context Token" do atendimento.
class _AccountContext {
  const _AccountContext({
    required this.userName,
    required this.plans,
    required this.currentPlanId,
    required this.contract,
  });

  final String userName;
  final List<SubscriptionPlanEntity> plans;
  final String currentPlanId;
  final ContractedSubscriptionEntity? contract;

  SubscriptionPlanEntity? planById(String? id) {
    if (id == null) return null;
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  SubscriptionPlanEntity? get currentPlan => planById(currentPlanId);

  String get firstName => userName.trim().split(' ').first;
}

/// Contratação proposta pelo Toke e ainda não confirmada.
class _PlanDraft {
  const _PlanDraft({required this.plan, required this.billingCycle});

  final SubscriptionPlanEntity plan;
  final SubscriptionBillingCycle billingCycle;
}

/// Toke — concierge de suporte, conta e planos do CareHub+.
class TokeAssistantRepository implements AssistantRepository {
  TokeAssistantRepository({
    TokeInterpreterClient? interpreter,
    CaregiverProfileRepository? profileRepository,
    SubscriptionsRepository? subscriptionsRepository,
  }) : this._(
         interpreter ?? TokeInterpreterClient(),
         profileRepository ?? CaregiverProfileRepository(),
         subscriptionsRepository,
       );

  /// Garante que perfil e assinaturas usem a mesma instância de repositório.
  TokeAssistantRepository._(
    this._interpreter,
    this._profileRepository,
    SubscriptionsRepository? subscriptionsRepository,
  ) : _subscriptionsRepository =
          subscriptionsRepository ??
          SubscriptionsRepository(profileRepository: _profileRepository);

  /// Triagem com IA, feita no backend (a chave do Gemini não fica no app).
  final TokeInterpreterClient _interpreter;
  final CaregiverProfileRepository _profileRepository;
  final SubscriptionsRepository _subscriptionsRepository;

  /// Contexto da conta carregado na abertura e renovado após contratação.
  _AccountContext? _account;

  /// Última contratação proposta, aguardando confirmação.
  _PlanDraft? _pendingPlanDraft;

  /// Carrega o contexto da conta. Falhas viram `null`: o Toke continua
  /// atendendo, apenas sem dados personalizados.
  Future<_AccountContext?> _loadAccount({bool refresh = false}) async {
    if (!refresh && _account != null) return _account;

    try {
      final results = await Future.wait([
        _profileRepository.fetchProfileWithPlan(),
        _subscriptionsRepository.fetchSubscriptions(),
      ]);
      final profile = results[0] as CaregiverProfileSnapshot;
      final subscriptions = results[1] as SubscriptionsSnapshot;

      _account = _AccountContext(
        userName: profile.profile.name,
        plans: subscriptions.plans,
        currentPlanId: subscriptions.currentPlanId,
        contract: subscriptions.contractedSubscription,
      );
    } catch (_) {
      _account = null;
    }
    return _account;
  }

  @override
  Future<List<AssistantMessage>> fetchInitialMessages() async {
    final account = await _loadAccount();

    return [
      _assistantMessage(
        _openingText(account),
        quickReplies: const [
          _plansReply,
          _paymentReply,
          _appGuidanceReply,
          _humanReply,
        ],
      ),
    ];
  }

  /// Abertura com diagnóstico: o Toke já começa pelo que sabe da conta.
  String _openingText(_AccountContext? account) {
    if (account == null) {
      return 'Olá! Eu sou o Toke, concierge digital do CareHub+. Não consegui '
          'consultar os dados da sua conta agora, mas posso ajudar com '
          'dúvidas sobre o app e os planos. Como posso ajudar?';
    }

    final greeting = account.firstName.isEmpty
        ? 'Olá! Eu sou o Toke, concierge digital do CareHub+.'
        : 'Olá, ${account.firstName}! Eu sou o Toke, concierge digital do '
              'CareHub+.';
    final pendency = _pendencies(account);
    final planStatus = pendency ?? _planStatusSentence(account);

    return '$greeting $planStatus Como posso ajudar?';
  }

  String _planStatusSentence(_AccountContext account) {
    final contract = account.contract;
    if (contract != null) {
      return 'Vi que você está no plano ${contract.planNameSnapshot} '
          '(${contract.billingCycle.label.toLowerCase()}, '
          '${_formatCents(contract.amountCents)}).';
    }
    final plan = account.currentPlan;
    return plan == null
        ? 'Você ainda não tem um plano contratado.'
        : 'Vi que você está no plano ${plan.name}.';
  }

  /// Pendências que o app consegue detectar com os dados que possui.
  String? _pendencies(_AccountContext account) {
    final contract = account.contract;
    if (contract != null && !contract.isActive) {
      return 'Notei que o seu contrato do plano ${contract.planNameSnapshot} '
          'não está ativo. Posso ajudar a regularizar ou escolher outro plano.';
    }
    if (account.plans.isEmpty) {
      return 'O catálogo de planos não está disponível no momento, então não '
          'consigo mostrar valores agora.';
    }
    return null;
  }

  @override
  Future<AssistantMessage> sendMessage({
    required String text,
    required List<AssistantMessage> history,
    String? intent,
  }) async {
    // Ações determinísticas não dependem do Gemini.
    if (intent == _TokeIntents.confirmPlan) return _confirmPendingPlan();
    if (intent == _TokeIntents.cancelPlan) {
      _pendingPlanDraft = null;
      return _assistantMessage(
        'Tudo bem, nada foi alterado no seu plano. Posso ajudar em algo mais?',
        quickReplies: _defaultReplies,
      );
    }

    final account = await _loadAccount();

    if (intent == _TokeIntents.plans) return _comparePlans(account);
    if (intent == _TokeIntents.payment) return _paymentRequest(account);
    if (intent == _TokeIntents.human) {
      return _humanHandoff(account, summary: null);
    }
    if (intent != null && intent.startsWith(_TokeIntents.proposePlanPrefix)) {
      final parts = intent
          .substring(_TokeIntents.proposePlanPrefix.length)
          .split(':');
      return _proposePlan(
        account,
        planId: parts.first,
        cycle: parts.length > 1 ? parts[1] : null,
      );
    }

    try {
      final result = await _interpreter.interpret(
        text: text,
        history: history,
        context: _contextFor(account),
        planIds: account?.plans.map((plan) => plan.id).toList() ?? [],
      );

      return switch (result.kind) {
        SupportIntentKind.simulatePlan => _simulatePlan(
          account,
          planId: result.planId,
          cycle: result.billingCycle,
        ),
        SupportIntentKind.contractPlan => _proposePlan(
          account,
          planId: result.planId,
          cycle: result.billingCycle,
        ),
        SupportIntentKind.payment => _paymentRequest(
          account,
          type: result.paymentType,
        ),
        SupportIntentKind.humanHandoff => _humanHandoff(
          account,
          summary: result.summary ?? text,
        ),
        SupportIntentKind.conversation => _assistantMessage(
          result.reply,
          quickReplies: _defaultReplies,
        ),
      };
    } on AppException catch (error) {
      return _assistantMessage(
        '${error.message} Você pode tentar novamente ou usar os atalhos.',
        quickReplies: _defaultReplies,
      );
    } catch (_) {
      return _assistantMessage(
        'Não consegui consultar o Toke agora. Tente novamente em instantes.',
        quickReplies: _defaultReplies,
      );
    }
  }

  /// Lista o catálogo com valores reais, sem passar pelo modelo.
  AssistantMessage _comparePlans(_AccountContext? account) {
    if (account == null || account.plans.isEmpty) {
      return _assistantMessage(
        'Não consegui carregar o catálogo de planos agora. Você também pode '
        'consultar em Configurações > Planos.',
        quickReplies: const [_humanReply, _appGuidanceReply],
      );
    }

    final lines = account.plans.map((plan) {
      final current = plan.id == account.currentPlanId ? ' (seu plano)' : '';
      return '• ${plan.name}$current: ${_priceSentence(plan)}';
    });

    return _assistantMessage(
      'Estes são os planos disponíveis:\n${lines.join('\n')}\n\n'
      'Quer simular ou contratar algum deles?',
      quickReplies: _upgradeReplies(account),
    );
  }

  /// Simula um plano com os valores do catálogo (cálculo feito pelo app).
  AssistantMessage _simulatePlan(
    _AccountContext? account, {
    required String? planId,
    required String? cycle,
  }) {
    final plan = account?.planById(planId);
    if (account == null || plan == null) return _comparePlans(account);

    final buffer = StringBuffer('Simulação do plano ${plan.name}: ')
      ..write(_priceSentence(plan));
    if (!plan.isFree && plan.annualSavings > 0) {
      buffer.write(
        ' No anual você economiza ${_formatReais(plan.annualSavings)} '
        '(${plan.annualDiscountPercentFromSavings}%).',
      );
    }
    if (plan.benefits.isNotEmpty) {
      buffer.write('\nInclui: ${plan.benefits.join(', ')}.');
    }
    if (plan.id == account.currentPlanId) {
      buffer.write('\nEste já é o seu plano atual.');
      return _assistantMessage(
        buffer.toString(),
        quickReplies: _defaultReplies,
      );
    }

    return _assistantMessage(
      buffer.toString(),
      quickReplies: [
        ..._contractRepliesFor(plan, preferredCycle: cycle),
        _plansReply,
      ],
    );
  }

  /// Monta a proposta de contratação e aguarda confirmação explícita.
  AssistantMessage _proposePlan(
    _AccountContext? account, {
    required String? planId,
    required String? cycle,
  }) {
    final plan = account?.planById(planId);
    if (account == null || plan == null) {
      _pendingPlanDraft = null;
      return _comparePlans(account);
    }

    final contract = account.contract;
    if (plan.id == account.currentPlanId &&
        contract != null &&
        contract.isActive) {
      _pendingPlanDraft = null;
      return _assistantMessage(
        'Você já está no plano ${plan.name}. Quer comparar com outro plano?',
        quickReplies: _defaultReplies,
      );
    }

    final billingCycle = plan.isFree
        ? SubscriptionBillingCycle.monthly
        : _cycleFrom(cycle);
    _pendingPlanDraft = _PlanDraft(plan: plan, billingCycle: billingCycle);

    // Texto montado pelo app: não depende do modelo dizer que contratou.
    final price = plan.isFree
        ? 'sem custo'
        : billingCycle == SubscriptionBillingCycle.annual
        ? '${_formatReais(plan.annualPriceFor())} por ano'
        : '${_formatReais(plan.monthlyPrice)} por mês';

    return _assistantMessage(
      'Quer que eu contrate o plano ${plan.name} '
      '(${billingCycle.label.toLowerCase()}, $price)? O contrato fica '
      'registrado na sua conta; a cobrança ainda não é processada pelo app.',
      quickReplies: const [_confirmPlanReply, _cancelPlanReply],
    );
  }

  /// Contrata de fato, reutilizando o mesmo fluxo da tela de Assinaturas.
  Future<AssistantMessage> _confirmPendingPlan() async {
    final draft = _pendingPlanDraft;
    if (draft == null) {
      return _assistantMessage(
        'Não há nenhuma contratação aguardando confirmação. Quer ver os planos?',
        quickReplies: _defaultReplies,
      );
    }

    try {
      final contract = await _subscriptionsRepository.contractPlan(
        plan: draft.plan,
        billingCycle: draft.billingCycle,
      );
      _pendingPlanDraft = null;
      await _loadAccount(refresh: true);

      return _assistantMessage(
        '✅ Pronto! Seu plano agora é o ${contract.planNameSnapshot} '
        '(${contract.billingCycle.label.toLowerCase()}, '
        '${_formatCents(contract.amountCents)}). Você pode conferir em '
        'Configurações > Planos.',
        quickReplies: const [_appGuidanceReply, _humanReply],
      );
    } catch (_) {
      return _assistantMessage(
        'Não consegui registrar a contratação agora. Tente confirmar de novo '
        'em instantes ou contrate por Configurações > Planos.',
        quickReplies: const [_confirmPlanReply, _cancelPlanReply],
      );
    }
  }

  /// Pedidos de Pix, fatura e cartão: explica com honestidade o que falta.
  AssistantMessage _paymentRequest(_AccountContext? account, {String? type}) {
    final action = switch (type) {
      'pix' => 'gerar um código Pix',
      'fatura' => 'emitir fatura ou segunda via',
      'cartao' => 'atualizar o cartão de crédito',
      _ => 'processar pagamentos',
    };
    final contract = account?.contract;
    final contractNote = contract == null
        ? ''
        : ' Pelo seu contrato, o valor registrado é '
              '${_formatCents(contract.amountCents)} '
              '(${contract.billingCycle.label.toLowerCase()}).';

    return _assistantMessage(
      'Ainda não consigo $action pelo chat: o CareHub+ não tem um gateway de '
      'pagamento integrado.$contractNote Se precisar, preparo o seu caso para '
      'um atendente, sem você repetir nada.',
      quickReplies: const [_humanReply, _plansReply],
    );
  }

  /// Prepara o repasse para um humano com o contexto preservado.
  AssistantMessage _humanHandoff(_AccountContext? account, {String? summary}) {
    final lines = <String>[
      if (account != null && account.userName.isNotEmpty)
        '• Cuidador: ${account.userName}',
      if (account != null) '• ${_planStatusSentence(account)}',
      if (summary != null && summary.trim().isNotEmpty)
        '• Solicitação: ${summary.trim()}',
    ];
    final caseSummary = lines.isEmpty
        ? ''
        : '\n\nResumo do seu caso:\n${lines.join('\n')}';

    return _assistantMessage(
      'Entendi, isso precisa de um atendente. O atendimento humano ainda não '
      'está conectado ao app, então não consigo transferir agora.$caseSummary'
      '\n\nEnquanto isso, posso tentar ajudar por aqui.',
      quickReplies: const [_plansReply, _appGuidanceReply],
    );
  }

  /// Atalhos de contratação para os planos diferentes do atual.
  List<AssistantQuickReply> _upgradeReplies(_AccountContext account) {
    return account.plans
        .where((plan) => plan.id != account.currentPlanId)
        .map(
          (plan) => AssistantQuickReply(
            label: 'Contratar ${plan.name}',
            intent: '${_TokeIntents.proposePlanPrefix}${plan.id}:monthly',
          ),
        )
        .toList();
  }

  List<AssistantQuickReply> _contractRepliesFor(
    SubscriptionPlanEntity plan, {
    String? preferredCycle,
  }) {
    if (plan.isFree) {
      return [
        AssistantQuickReply(
          label: 'Contratar ${plan.name}',
          intent: '${_TokeIntents.proposePlanPrefix}${plan.id}:monthly',
        ),
      ];
    }
    final cycles = preferredCycle == 'annual'
        ? SubscriptionBillingCycle.values.reversed
        : SubscriptionBillingCycle.values;
    return cycles
        .map(
          (cycle) => AssistantQuickReply(
            label: 'Contratar ${plan.name} (${cycle.label.toLowerCase()})',
            intent: '${_TokeIntents.proposePlanPrefix}${plan.id}:${cycle.name}',
          ),
        )
        .toList();
  }

  SubscriptionBillingCycle _cycleFrom(String? value) =>
      value == SubscriptionBillingCycle.annual.name
      ? SubscriptionBillingCycle.annual
      : SubscriptionBillingCycle.monthly;

  String _priceSentence(SubscriptionPlanEntity plan) {
    if (plan.isFree) return 'gratuito.';
    final annualMonthly = plan.monthlyEquivalentFor(
      SubscriptionBillingCycle.annual,
    );
    return '${_formatReais(plan.monthlyPrice)}/mês ou '
        '${_formatReais(plan.annualPriceFor())}/ano '
        '(${_formatReais(annualMonthly)}/mês).';
  }

  /// Context Token enviado ao Gemini: só o necessário para o atendimento.
  Map<String, dynamic> _contextFor(_AccountContext? account) {
    if (account == null) return const {'contextAvailable': false};

    final catalog = account.plans
        .map((plan) {
          final annual = plan.isFree
              ? 'gratuito'
              : _formatReais(plan.annualPriceFor());
          return '${plan.id} | ${plan.name} | '
              '${_formatReais(plan.monthlyPrice)} | $annual | '
              '${plan.benefits.join(', ')}';
        })
        .join('\n');
    final contract = account.contract;

    return {
      'contextAvailable': true,
      'userName': account.userName,
      'currentPlan': account.currentPlan?.name ?? 'nenhum plano contratado',
      'subscription': contract == null
          ? null
          : '${contract.planNameSnapshot}, '
                '${contract.billingCycle.label.toLowerCase()}, '
                '${_formatCents(contract.amountCents)}, status '
                '${contract.isActive ? 'ativo' : contract.status}',
      'pendencies': _pendencies(account),
      'catalog': catalog.isEmpty ? null : '\n$catalog',
    };
  }

  String _formatCents(int cents) => _formatReais(cents / 100);

  /// Formata em reais no padrão brasileiro (R$ 1.234,56).
  String _formatReais(double value) {
    final cents = (value * 100).round();
    final reais = (cents ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final decimals = (cents % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$decimals';
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

  String _newMessageId() => 'toke_${DateTime.now().microsecondsSinceEpoch}';
}
