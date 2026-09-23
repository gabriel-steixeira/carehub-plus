/*
 * CareHub Plus — Dados / Repositório de Perfil do Cuidador
 *
 * Único ponto autorizado a ler e gravar o perfil cadastral do cuidador logado
 * em `caregivers/{uid}`. Nem os widgets nem o BLoC tocam o Firebase: eles só
 * conhecem as entidades de domínio devolvidas aqui.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../subscriptions/data/models/contracted_subscription_model.dart';
import '../../../subscriptions/data/models/subscription_plan_model.dart';
import '../../../subscriptions/domain/entities/contracted_subscription_entity.dart';
import '../../../subscriptions/domain/entities/subscription_plan_entity.dart';
import '../../domain/entities/caregiver_profile_entity.dart';
import '../models/caregiver_profile_model.dart';

/// Perfil cadastral, plano de catálogo e contrato ativo do cuidador.
typedef CaregiverProfileSnapshot = ({
  CaregiverProfileEntity profile,
  SubscriptionPlanEntity? plan,
  String? planId,
  ContractedSubscriptionEntity? contractedSubscription,
});

/// Leitura e gravação do perfil e do plano do cuidador autenticado.
class CaregiverProfileRepository {
  CaregiverProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const String _caregiversCollection = 'caregivers';
  static const String _plansCollection = 'subscriptionPlans';
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _planIdField = 'planId';
  static const String _activeSubscriptionIdField = 'activeSubscriptionId';

  /// Perfil, plano do catálogo e snapshot do contrato ativo.
  ///
  /// O catálogo pode mudar sem alterar o contrato já registrado. Quando há um
  /// contrato, ele é a fonte do identificador atual; os dados comerciais
  /// históricos continuam no snapshot da subcoleção do cuidador.
  Future<CaregiverProfileSnapshot> fetchProfileWithPlan() async {
    final user = _currentUser;

    try {
      final doc = await _firestore
          .collection(_caregiversCollection)
          .doc(user.uid)
          .get();
      final data = doc.data();

      if (data == null) {
        return (
          profile: CaregiverProfileEntity(
            id: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            photoUrl: _nonEmpty(user.photoURL),
          ),
          plan: null,
          planId: null,
          contractedSubscription: null,
        );
      }

      final stored = CaregiverProfileModel.fromJson({...data, 'id': user.uid});
      final activeSubscriptionId = _nonEmpty(data[_activeSubscriptionIdField]);
      final contractedSubscription = await _fetchActiveSubscription(
        user.uid,
        activeSubscriptionId,
      );
      final requestedPlanId =
          contractedSubscription?.planId ?? _nonEmpty(data[_planIdField]);
      final plan = await _fetchPlan(requestedPlanId);

      return (
        profile: CaregiverProfileEntity(
          id: stored.id,
          name: stored.name.isNotEmpty ? stored.name : (user.displayName ?? ''),
          email: stored.email.isNotEmpty ? stored.email : (user.email ?? ''),
          phone: stored.phone,
          birthDate: stored.birthDate,
          gender: stored.gender,
          photoUrl: stored.hasPhoto
              ? stored.photoUrl
              : _nonEmpty(user.photoURL),
          photoBase64: stored.photoBase64,
        ),
        plan: plan,
        planId: requestedPlanId,
        contractedSubscription: contractedSubscription,
      );
    } on FirebaseException catch (e) {
      // Mensagem própria em português: o texto do Firebase vem em inglês e não
      // pode ser exibido para a cuidadora. O `code` fica para diagnóstico.
      throw AppException('Não foi possível carregar seu perfil.', code: e.code);
    }
  }

  /// Grava os dados editados do perfil.
  ///
  /// Usa `merge` para tocar apenas os campos deste formulário, preservando o
  /// resto do documento (preferências de notificação, plano, `createdAt`).
  Future<void> updateProfile(CaregiverProfileEntity profile) async {
    final user = _currentUser;
    final model = CaregiverProfileModel.fromEntity(profile);

    try {
      await _firestore
          .collection(_caregiversCollection)
          .doc(user.uid)
          .set(model.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException('Não foi possível salvar seu perfil.', code: e.code);
    }
  }

  /// Registra uma nova contratação com um snapshot do preço e das condições.
  ///
  /// O documento anterior permanece no histórico e deixa de ser ativo. O
  /// `activeSubscriptionId` aponta somente para a contratação vigente.
  Future<ContractedSubscriptionEntity> createSubscription({
    required SubscriptionPlanEntity plan,
    required SubscriptionBillingCycle billingCycle,
  }) async {
    final user = _currentUser;
    final now = DateTime.now();
    final caregiverReference = _firestore
        .collection(_caregiversCollection)
        .doc(user.uid);
    final subscriptionReference = caregiverReference
        .collection(_subscriptionsCollection)
        .doc();

    final monthlyPriceCents = _toCents(plan.monthlyPrice);
    final annualPriceCents = _toCents(plan.annualPriceFor());
    final amountCents = billingCycle == SubscriptionBillingCycle.annual
        ? annualPriceCents
        : monthlyPriceCents;
    final subscription = ContractedSubscriptionModel(
      id: subscriptionReference.id,
      planId: plan.id,
      planNameSnapshot: plan.name,
      billingCycle: billingCycle,
      amountCents: amountCents,
      monthlyPriceCents: monthlyPriceCents,
      annualPriceCents: annualPriceCents,
      maxMembersSnapshot: plan.maxMembers,
      benefitsSnapshot: List<String>.unmodifiable(plan.benefits),
      currency: 'BRL',
      status: 'active',
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final caregiverSnapshot = await caregiverReference.get();
      final previousSubscriptionId = _nonEmpty(
        caregiverSnapshot.data()?[_activeSubscriptionIdField],
      );
      final batch = _firestore.batch();

      if (previousSubscriptionId != null) {
        final previousReference = caregiverReference
            .collection(_subscriptionsCollection)
            .doc(previousSubscriptionId);
        final previousSnapshot = await previousReference.get();
        if (previousSnapshot.exists) {
          batch.set(previousReference, {
            'status': 'superseded',
            'updatedAt': Timestamp.fromDate(now),
          }, SetOptions(merge: true));
        }
      }

      batch.set(subscriptionReference, {
        ...subscription.toJson(),
        'caregiverId': user.uid,
      });
      batch.set(caregiverReference, {
        _planIdField: plan.id,
        _activeSubscriptionIdField: subscription.id,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      await batch.commit();
      return subscription;
    } on FirebaseException catch (e) {
      throw AppException('Não foi possível registrar seu plano.', code: e.code);
    }
  }

  /// Mantém compatibilidade com integrações antigas que só atualizam o ID.
  Future<void> updatePlanId(String planId) async {
    final user = _currentUser;

    try {
      await _firestore.collection(_caregiversCollection).doc(user.uid).set({
        _planIdField: planId,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException('Não foi possível atualizar seu plano.', code: e.code);
    }
  }

  Future<SubscriptionPlanEntity?> _fetchPlan(String? planId) async {
    if (planId == null) return null;

    final doc = await _firestore.collection(_plansCollection).doc(planId).get();
    final data = doc.data();
    if (data == null) return null;

    return SubscriptionPlanModel.fromJson({...data, 'id': doc.id});
  }

  Future<ContractedSubscriptionEntity?> _fetchActiveSubscription(
    String caregiverId,
    String? subscriptionId,
  ) async {
    if (subscriptionId == null) return null;

    final doc = await _firestore
        .collection(_caregiversCollection)
        .doc(caregiverId)
        .collection(_subscriptionsCollection)
        .doc(subscriptionId)
        .get();
    final data = doc.data();
    if (data == null) return null;

    return ContractedSubscriptionModel.fromJson({...data, 'id': doc.id});
  }

  /// Usuário autenticado ou erro de sessão.
  User get _currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException('Entre na sua conta para acessar seu perfil.');
    }
    return user;
  }

  /// String vazia vinda do provedor ou do Firestore significa ausência de dado.
  static String? _nonEmpty(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  static int _toCents(double value) => (value * 100).round();
}
