/*
 * CareHub Plus — Dados / Repositório da caixa de notificações
 *
 * Único ponto do app que lê `notifications/{id}`. Entrega a lista em tempo
 * real (o sino atualiza sozinho quando o backend cria um aviso) e marca
 * avisos como lidos — a única escrita que as regras do Firestore permitem.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../models/app_notification_model.dart';

/// Leitura da caixa de notificações da pessoa logada.
class NotificationInboxRepository {
  NotificationInboxRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const String _collection = 'notifications';

  /// Id da pessoa logada a cada entrada e saída da conta (`null` = deslogado).
  Stream<String?> watchUserId() =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid).distinct();

  /// Avisos da pessoa, do mais novo para o mais antigo.
  ///
  /// A ordenação é feita aqui, e não no Firestore, para a consulta não
  /// depender de índice composto.
  Stream<List<AppNotificationEntity>> watchInbox(String uid) {
    return _firestore
        .collection(_collection)
        .where('recipientUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => AppNotificationModel.fromJson(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return List<AppNotificationEntity>.unmodifiable(items);
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw AppException(
              'Não foi possível carregar suas notificações.',
              code: error.code,
            );
          }
          throw error;
        });
  }

  /// Marca os avisos informados como lidos, numa única gravação.
  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.now();
    for (final id in notificationIds) {
      batch.update(_firestore.collection(_collection).doc(id), {'readAt': now});
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException(
        'Não foi possível marcar as notificações como lidas.',
        code: e.code,
      );
    }
  }
}
