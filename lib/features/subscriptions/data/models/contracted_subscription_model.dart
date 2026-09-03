/*
 * CareHub Plus — Dados / Modelo de Assinatura Contratada
 *
 * Converte o snapshot comercial persistido no Firestore para a entidade de
 * domínio. O modelo guarda o valor em centavos e nunca recalcula o contrato a
 * partir do catálogo atual.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/contracted_subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';

/// Modelo serializável da assinatura contratada.
class ContractedSubscriptionModel extends ContractedSubscriptionEntity {
  const ContractedSubscriptionModel({
    required super.id,
    required super.planId,
    required super.planNameSnapshot,
    required super.billingCycle,
    required super.amountCents,
    required super.monthlyPriceCents,
    required super.annualPriceCents,
    required super.maxMembersSnapshot,
    required super.benefitsSnapshot,
    required super.currency,
    required super.status,
    required super.startedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ContractedSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final createdAt = _asDate(json['createdAt']) ?? DateTime.now();
    final updatedAt = _asDate(json['updatedAt']) ?? createdAt;

    return ContractedSubscriptionModel(
      id: json['id'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      planNameSnapshot: json['planNameSnapshot'] as String? ?? '',
      billingCycle: _billingCycleFrom(json['billingCycle']),
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      monthlyPriceCents: (json['monthlyPriceCents'] as num?)?.toInt() ?? 0,
      annualPriceCents: (json['annualPriceCents'] as num?)?.toInt() ?? 0,
      maxMembersSnapshot: (json['maxMembersSnapshot'] as num?)?.toInt(),
      benefitsSnapshot: (json['benefitsSnapshot'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      currency: json['currency'] as String? ?? 'BRL',
      status: json['status'] as String? ?? 'active',
      startedAt: _asDate(json['startedAt']) ?? createdAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planNameSnapshot': planNameSnapshot,
      'billingCycle': billingCycle.name,
      'amountCents': amountCents,
      'monthlyPriceCents': monthlyPriceCents,
      'annualPriceCents': annualPriceCents,
      'maxMembersSnapshot': maxMembersSnapshot,
      'benefitsSnapshot': benefitsSnapshot,
      'currency': currency,
      'status': status,
      'startedAt': Timestamp.fromDate(startedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static SubscriptionBillingCycle _billingCycleFrom(dynamic value) {
    return value == SubscriptionBillingCycle.annual.name
        ? SubscriptionBillingCycle.annual
        : SubscriptionBillingCycle.monthly;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
