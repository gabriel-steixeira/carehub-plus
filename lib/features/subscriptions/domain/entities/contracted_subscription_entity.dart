/*
 * CareHub Plus — Domínio / Assinatura Contratada
 *
 * Representa o retrato imutável das condições registradas no momento em que
 * uma cuidadora escolheu um plano. O valor fica em centavos para não depender
 * de arredondamentos de ponto flutuante quando o catálogo mudar.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'subscription_plan_entity.dart';

/// Snapshot das condições comerciais de uma contratação.
class ContractedSubscriptionEntity extends Equatable {
  const ContractedSubscriptionEntity({
    required this.id,
    required this.planId,
    required this.planNameSnapshot,
    required this.billingCycle,
    required this.amountCents,
    required this.monthlyPriceCents,
    required this.annualPriceCents,
    required this.maxMembersSnapshot,
    required this.benefitsSnapshot,
    required this.currency,
    required this.status,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String planId;
  final String planNameSnapshot;
  final SubscriptionBillingCycle billingCycle;
  final int amountCents;
  final int monthlyPriceCents;
  final int annualPriceCents;
  final int? maxMembersSnapshot;
  final List<String> benefitsSnapshot;
  final String currency;
  final String status;
  final DateTime startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Valor registrado na contratação em reais, somente para apresentação.
  double get amount => amountCents / 100;

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
    id,
    planId,
    planNameSnapshot,
    billingCycle,
    amountCents,
    monthlyPriceCents,
    annualPriceCents,
    maxMembersSnapshot,
    benefitsSnapshot,
    currency,
    status,
    startedAt,
    createdAt,
    updatedAt,
  ];
}
