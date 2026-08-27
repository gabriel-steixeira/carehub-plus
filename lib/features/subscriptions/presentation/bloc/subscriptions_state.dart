/*
 * CareHub Plus — Apresentação / Estado de Assinaturas
 *
 * Reúne os dados renderizados pela tela e mantém o ciclo escolhido independente
 * do carregamento do catálogo.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

part of 'subscriptions_bloc.dart';

const _notProvided = Object();

enum SubscriptionsStatus { initial, loading, success, failure }

class SubscriptionsState extends Equatable {
  const SubscriptionsState({
    this.status = SubscriptionsStatus.initial,
    this.plans = const [],
    this.currentPlanId = '',
    this.caregiverPhotoUrl,
    this.billingCycle = SubscriptionBillingCycle.monthly,
    this.annualDiscountPercent = 0,
    this.contractedSubscription,
    this.errorMessage,
    this.feedbackMessage,
    this.feedbackSequence = 0,
  });

  final SubscriptionsStatus status;
  final List<SubscriptionPlanEntity> plans;
  final String currentPlanId;
  final String? caregiverPhotoUrl;
  final SubscriptionBillingCycle billingCycle;
  final int annualDiscountPercent;
  final ContractedSubscriptionEntity? contractedSubscription;
  final String? errorMessage;
  final String? feedbackMessage;
  final int feedbackSequence;

  SubscriptionsState copyWith({
    SubscriptionsStatus? status,
    List<SubscriptionPlanEntity>? plans,
    String? currentPlanId,
    Object? caregiverPhotoUrl = _notProvided,
    SubscriptionBillingCycle? billingCycle,
    int? annualDiscountPercent,
    Object? contractedSubscription = _notProvided,
    Object? errorMessage = _notProvided,
    Object? feedbackMessage = _notProvided,
    int? feedbackSequence,
  }) {
    return SubscriptionsState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      currentPlanId: currentPlanId ?? this.currentPlanId,
      caregiverPhotoUrl: identical(caregiverPhotoUrl, _notProvided)
          ? this.caregiverPhotoUrl
          : caregiverPhotoUrl as String?,
      billingCycle: billingCycle ?? this.billingCycle,
      annualDiscountPercent:
          annualDiscountPercent ?? this.annualDiscountPercent,
      contractedSubscription: identical(contractedSubscription, _notProvided)
          ? this.contractedSubscription
          : contractedSubscription as ContractedSubscriptionEntity?,
      errorMessage: identical(errorMessage, _notProvided)
          ? this.errorMessage
          : errorMessage as String?,
      feedbackMessage: identical(feedbackMessage, _notProvided)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackSequence: feedbackSequence ?? this.feedbackSequence,
    );
  }

  @override
  List<Object?> get props => [
    status,
    plans,
    currentPlanId,
    caregiverPhotoUrl,
    billingCycle,
    annualDiscountPercent,
    contractedSubscription,
    errorMessage,
    feedbackMessage,
    feedbackSequence,
  ];
}
