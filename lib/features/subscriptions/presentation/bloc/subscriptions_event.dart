/*
 * CareHub Plus — Apresentação / Eventos de Assinaturas
 *
 * Declara as intenções aceitas pelo BLoC para carregar dados, trocar o ciclo
 * exibido e tratar uma ação de plano.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

part of 'subscriptions_bloc.dart';

abstract class SubscriptionsEvent extends Equatable {
  const SubscriptionsEvent();

  @override
  List<Object?> get props => [];
}

class SubscriptionsLoadEvent extends SubscriptionsEvent {
  const SubscriptionsLoadEvent();
}

class SubscriptionsBillingCycleChangedEvent extends SubscriptionsEvent {
  const SubscriptionsBillingCycleChangedEvent(this.cycle);

  final SubscriptionBillingCycle cycle;

  @override
  List<Object?> get props => [cycle];
}

class SubscriptionsPlanActionEvent extends SubscriptionsEvent {
  const SubscriptionsPlanActionEvent(this.planId);

  final String planId;

  @override
  List<Object?> get props => [planId];
}
