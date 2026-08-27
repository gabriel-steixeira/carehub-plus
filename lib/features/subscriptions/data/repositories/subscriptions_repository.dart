/*
 * CareHub Plus — Dados / Repositório de Assinaturas
 *
 * Carrega o catálogo remoto e combina seus dados com o contrato ativo do
 * cuidador autenticado. A seleção do plano também é persistida aqui, mantendo
 * o acesso ao Firebase fora do BLoC e da interface.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../profile/data/repositories/caregiver_profile_repository.dart';
import '../../domain/entities/contracted_subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../models/subscription_plan_model.dart';

/// Dados necessários para montar a tela de assinaturas.
typedef SubscriptionsSnapshot = ({
  List<SubscriptionPlanEntity> plans,
  String currentPlanId,
  String? caregiverPhotoUrl,
  int annualDiscountPercent,
  SubscriptionBillingCycle billingCycle,
  ContractedSubscriptionEntity? contractedSubscription,
});

/// Fonte dos planos e da assinatura atual do cuidador.
class SubscriptionsRepository {
  SubscriptionsRepository({
    CaregiverProfileRepository? profileRepository,
    FirebaseFirestore? firestore,
    List<SubscriptionPlanEntity>? catalog,
  }) : _profileRepository = profileRepository ?? CaregiverProfileRepository(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _catalog = catalog;

  static const String _plansCollection = 'subscriptionPlans';

  final CaregiverProfileRepository _profileRepository;
  final FirebaseFirestore _firestore;
  final List<SubscriptionPlanEntity>? _catalog;

  Future<SubscriptionsSnapshot> fetchSubscriptions() async {
    final profileSnapshot = await _profileRepository.fetchProfileWithPlan();
    final plans = await _fetchCatalog();
    final contractedSubscription = profileSnapshot.contractedSubscription;
    final currentPlanId = _resolveCurrentPlanId(
      contractedSubscription?.planId ?? profileSnapshot.planId,
      plans,
    );

    return (
      plans: plans,
      currentPlanId: currentPlanId,
      caregiverPhotoUrl: profileSnapshot.profile.photoUrl,
      annualDiscountPercent: _highestAnnualDiscount(plans),
      billingCycle:
          contractedSubscription?.billingCycle ??
          SubscriptionBillingCycle.monthly,
      contractedSubscription: contractedSubscription,
    );
  }

  /// Registra a contratação com snapshot do preço e das condições do catálogo.
  Future<ContractedSubscriptionEntity> contractPlan({
    required SubscriptionPlanEntity plan,
    required SubscriptionBillingCycle billingCycle,
  }) {
    return _profileRepository.createSubscription(
      plan: plan,
      billingCycle: billingCycle,
    );
  }

  Future<List<SubscriptionPlanEntity>> _fetchCatalog() async {
    final catalog = _catalog;
    if (catalog != null) {
      return List<SubscriptionPlanEntity>.unmodifiable(catalog);
    }

    try {
      final snapshot = await _firestore.collection(_plansCollection).get();
      final plans = snapshot.docs
          .map(
            (doc) =>
                SubscriptionPlanModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList(growable: false);

      return List<SubscriptionPlanEntity>.unmodifiable(plans);
    } on FirebaseException catch (e) {
      // Mensagem própria em português: o texto do Firebase vem em inglês e não
      // pode ser exibido para a cuidadora. O `code` fica para diagnóstico.
      throw AppException('Não foi possível carregar os planos.', code: e.code);
    }
  }

  String _resolveCurrentPlanId(
    String? currentPlanId,
    List<SubscriptionPlanEntity> plans,
  ) {
    if (currentPlanId == null) return '';
    return plans.any((plan) => plan.id == currentPlanId) ? currentPlanId : '';
  }

  /// Maior desconto anual do catálogo, calculado a partir da economia real.
  int _highestAnnualDiscount(List<SubscriptionPlanEntity> plans) {
    var highest = 0;
    for (final plan in plans) {
      final discount = plan.annualDiscountPercentFromSavings;
      if (discount > highest) highest = discount;
    }
    return highest;
  }
}
