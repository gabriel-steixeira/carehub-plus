/*
 * CareHub Plus — Domínio / Plano de Assinatura
 *
 * Representa um plano disponível e calcula o valor mensal equivalente de cada
 * ciclo sem acoplar as regras do catálogo aos widgets da tela.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Ciclos de cobrança disponíveis para uma assinatura.
enum SubscriptionBillingCycle {
  monthly('Mensal'),
  annual('Anual');

  const SubscriptionBillingCycle(this.label);

  final String label;
}

/// Plano oferecido no catálogo de assinaturas.
class SubscriptionPlanEntity extends Equatable {
  const SubscriptionPlanEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.annualDiscountPercent,
    required this.benefits,
    required this.actionLabel,
    this.maxMembers,
    this.annualPrice,
    this.badgeLabel,
    this.footnote,
  });

  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final int annualDiscountPercent;
  final List<String> benefits;
  final String actionLabel;
  final double? annualPrice;
  final String? badgeLabel;

  /// Quantidade máxima de pessoas/dependentes coberta pelo plano.
  final int? maxMembers;

  /// Observação comercial exibida abaixo da ação (teste, cupons, condições).
  final String? footnote;

  bool get isFree => monthlyPrice == 0;

  /// Valor total cobrado no ciclo anual, quando aplicável.
  double annualPriceFor() {
    if (isFree) return 0;

    return annualPrice ?? monthlyPrice * 12 * (1 - annualDiscountPercent / 100);
  }

  /// Valor por mês. No ciclo anual, usa o valor anual promocional do plano.
  double monthlyEquivalentFor(SubscriptionBillingCycle cycle) {
    if (cycle == SubscriptionBillingCycle.monthly || isFree) {
      return monthlyPrice;
    }

    return annualPriceFor() / 12;
  }

  /// Economia obtida ao pagar pelo ciclo anual em vez de doze meses avulsos.
  double get annualSavings => monthlyPrice * 12 - annualPriceFor();

  /// Desconto anual em porcentagem derivado da economia real do plano.
  int get annualDiscountPercentFromSavings {
    final fullPrice = monthlyPrice * 12;
    if (fullPrice <= 0) return 0;

    return (annualSavings / fullPrice * 100).round();
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    monthlyPrice,
    annualDiscountPercent,
    benefits,
    actionLabel,
    maxMembers,
    annualPrice,
    badgeLabel,
    footnote,
  ];
}
