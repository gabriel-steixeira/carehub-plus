/*
 * CareHub Plus — Dados / Repositório de Preferências de Notificação
 *
 * Único ponto do app autorizado a ler e gravar as preferências de notificação
 * no Firestore. Grava em `caregivers/{uid}.notificationPreferences`, um campo
 * separado do `settings` já usado por Configurações, para que as duas telas não
 * disputem o mesmo mapa.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../models/notification_preferences_model.dart';

/// Leitura e gravação das preferências de notificação do cuidador logado.
class NotificationPreferencesRepository {
  NotificationPreferencesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const String _collection = 'caregivers';
  static const String _field = 'notificationPreferences';

  /// Preferências gravadas para o cuidador logado.
  ///
  /// Sem usuário logado ou sem nada gravado ainda, devolve os padrões do
  /// domínio — a tela nunca abre vazia.
  Future<NotificationPreferencesEntity> fetchPreferences() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return NotificationPreferencesEntity.defaults();

    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      final raw = doc.data()?[_field];
      if (raw is! Map) return NotificationPreferencesEntity.defaults();

      return NotificationPreferencesModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on FirebaseException catch (e) {
      throw AppException(
        e.message ??
            'Não foi possível carregar suas preferências de notificação.',
        code: e.code,
      );
    }
  }

  /// Grava uma única preferência.
  ///
  /// Atualiza apenas a chave interna alterada, sem reescrever as outras
  /// preferências nem o restante do documento do cuidador.
  Future<void> updatePreference(
    NotificationPreference preference,
    bool enabled,
  ) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const AppException(
        'Entre na sua conta para salvar suas preferências de notificação.',
      );
    }

    try {
      await _firestore.collection(_collection).doc(uid).update({
        '$_field.${preference.storageKey}': enabled,
      });
    } on FirebaseException catch (e) {
      throw AppException(
        e.message ?? 'Não foi possível salvar sua preferência de notificação.',
        code: e.code,
      );
    }
  }
}
