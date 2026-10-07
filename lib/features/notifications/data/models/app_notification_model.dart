/*
 * CareHub Plus — Dados / Modelo de Notificação do app
 *
 * Converte o documento `notifications/{id}` gravado pelo backend em
 * `AppNotificationEntity`. Só esta camada conhece `Timestamp` e as chaves do
 * Firestore. Campos ausentes viram valores neutros em vez de erro.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification_entity.dart';

/// Modelo de leitura de [AppNotificationEntity].
class AppNotificationModel extends AppNotificationEntity {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.createdAt,
    super.relatedId,
    super.readAt,
  });

  factory AppNotificationModel.fromJson(String id, Map<String, dynamic> json) {
    return AppNotificationModel(
      id: id,
      type: AppNotificationType.fromStorageKey(json['type'] as String?),
      title: json['title'] as String? ?? 'Notificação',
      body: json['body'] as String? ?? '',
      // Sem data (documento antigo ou em gravação) vai para o fim da lista.
      createdAt:
          _parseDate(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      relatedId: json['relatedId'] as String?,
      readAt: _parseDate(json['readAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
