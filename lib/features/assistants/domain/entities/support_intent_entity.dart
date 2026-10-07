/*
 * CareHub Plus — Domínio / Triagem do Toke
 *
 * Resultado da interpretação de uma mensagem pelo Toke: a ação sugerida e os
 * dados extraídos. Quem interpreta é o backend; quem executa (simular,
 * contratar após confirmação, repassar a um humano) continua sendo o app.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Ação que o Toke identificou na mensagem do cuidador.
enum SupportIntentKind {
  /// Dúvida resolvida só com conversa (navegação, conta, planos).
  conversation('conversation'),

  /// Comparar valores de um plano sem contratar nada.
  simulatePlan('simulate_plan'),

  /// Pedido para trocar de plano; exige confirmação antes de gravar.
  contractPlan('contract_plan'),

  /// Pix, fatura ou cartão: dependem de um gateway de pagamento.
  payment('payment'),

  /// Pedido explícito de atendimento humano.
  humanHandoff('human_handoff');

  const SupportIntentKind(this.value);

  /// Valor devolvido pelo backend.
  final String value;

  static SupportIntentKind fromValue(String? value) {
    for (final kind in SupportIntentKind.values) {
      if (kind.value == value) return kind;
    }
    return SupportIntentKind.conversation;
  }
}

/// Resultado estruturado da triagem feita pelo Toke.
class SupportIntentResult extends Equatable {
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

  @override
  List<Object?> get props => [
    kind,
    reply,
    planId,
    billingCycle,
    paymentType,
    summary,
  ];
}
