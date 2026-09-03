/*
 * CareHub Plus — Apresentação / BLoC de Assinaturas
 *
 * Carrega o catálogo, controla o ciclo de cobrança selecionado e registra o
 * snapshot da contratação sem recalcular valores históricos pelo catálogo.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/subscriptions_repository.dart';
import '../../domain/entities/contracted_subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';

part 'subscriptions_event.dart';
part 'subscriptions_state.dart';

class SubscriptionsBloc extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  SubscriptionsBloc({required SubscriptionsRepository repository})
    : _repository = repository,
      super(const SubscriptionsState()) {
    on<SubscriptionsLoadEvent>(_onLoad);
    on<SubscriptionsBillingCycleChangedEvent>(_onBillingCycleChanged);
    on<SubscriptionsPlanActionEvent>(_onPlanAction);
  }

  final SubscriptionsRepository _repository;

  Future<void> _onLoad(
    SubscriptionsLoadEvent event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(
      state.copyWith(status: SubscriptionsStatus.loading, errorMessage: null),
    );

    try {
      final snapshot = await _repository.fetchSubscriptions();
      emit(
        state.copyWith(
          status: SubscriptionsStatus.success,
          plans: snapshot.plans,
          currentPlanId: snapshot.currentPlanId,
          caregiverPhotoUrl: snapshot.caregiverPhotoUrl,
          annualDiscountPercent: snapshot.annualDiscountPercent,
          billingCycle: snapshot.billingCycle,
          contractedSubscription: snapshot.contractedSubscription,
          errorMessage: null,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: SubscriptionsStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  void _onBillingCycleChanged(
    SubscriptionsBillingCycleChangedEvent event,
    Emitter<SubscriptionsState> emit,
  ) {
    emit(state.copyWith(billingCycle: event.cycle));
  }

  Future<void> _onPlanAction(
    SubscriptionsPlanActionEvent event,
    Emitter<SubscriptionsState> emit,
  ) async {
    if (event.planId == state.currentPlanId &&
        state.contractedSubscription != null) {
      return;
    }

    SubscriptionPlanEntity? selectedPlan;
    for (final plan in state.plans) {
      if (plan.id == event.planId) {
        selectedPlan = plan;
        break;
      }
    }
    if (selectedPlan == null) return;

    try {
      final contractedSubscription = await _repository.contractPlan(
        plan: selectedPlan,
        billingCycle: state.billingCycle,
      );
      emit(
        state.copyWith(
          currentPlanId: event.planId,
          contractedSubscription: contractedSubscription,
          feedbackMessage:
              'Plano ${selectedPlan.name} contratado com o valor registrado.',
          feedbackSequence: state.feedbackSequence + 1,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          feedbackMessage: error.message,
          feedbackSequence: state.feedbackSequence + 1,
        ),
      );
    }
  }
}
