/*
 * CareHub Plus — Dados / Modelo de Plano de Assinatura
 *
 * Converte os dados do catálogo remoto para a entidade de domínio. Os valores
 * comerciais não pertencem ao código: são administrados nos documentos da
 * coleção `subscriptionPlans` do Firestore.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../domain/entities/subscription_plan_entity.dart';

/// Modelo serializável de um plano do catálogo.
class SubscriptionPlanModel extends SubscriptionPlanEntity {
  const SubscriptionPlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.monthlyPrice,
    required super.annualDiscountPercent,
    required super.benefits,
    required super.actionLabel,
    required super.maxMembers,
    super.annualPrice,
    super.badgeLabel,
    super.footnote,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'] as List<dynamic>? ?? const [];

    return SubscriptionPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble() ?? 0,
      annualDiscountPercent:
          (json['annualDiscountPercent'] as num?)?.toInt() ?? 0,
      benefits: rawBenefits.whereType<String>().toList(growable: false),
      actionLabel: json['actionLabel'] as String? ?? '',
      maxMembers: (json['maxMembers'] as num?)?.toInt(),
      annualPrice: (json['annualPrice'] as num?)?.toDouble(),
      badgeLabel: json['badgeLabel'] as String?,
      footnote: json['footnote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'annualDiscountPercent': annualDiscountPercent,
      'benefits': benefits,
      'actionLabel': actionLabel,
      'maxMembers': maxMembers,
      'annualPrice': annualPrice,
      'badgeLabel': badgeLabel,
      'footnote': footnote,
    };
  }
}
