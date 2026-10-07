/*
 * CareHub Plus — Domínio / Notificação do app
 *
 * Um aviso recebido pela pessoa logada: foi acionada num SOS, incluída numa
 * tarefa ou num chat novo. Quem cria é o backend (Cloud Functions); o app só
 * lê e marca como lida. Dart puro — nenhuma dependência de Flutter ou
 * Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Assunto do aviso. Define o ícone e a cor na lista.
enum AppNotificationType {
  sos('sos'),
  task('task'),
  chat('chat'),

  /// Tipo gravado por uma versão mais nova do backend.
  unknown('unknown');

  const AppNotificationType(this.storageKey);

  /// Valor gravado no Firestore.
  final String storageKey;

  static AppNotificationType fromStorageKey(String? key) {
    for (final type in values) {
      if (type.storageKey == key) return type;
    }
    return AppNotificationType.unknown;
  }
}

/// Aviso exibido no sino e na lista de notificações.
class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.relatedId,
    this.readAt,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Id da tarefa, do chat ou do alerta que gerou o aviso.
  final String? relatedId;

  /// Quando foi lida. `null` enquanto não foi aberta.
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    createdAt,
    relatedId,
    readAt,
  ];
}
