/*
 * CareHub Plus — Dados / Modelo de Preferências de Notificação
 *
 * Espelha `NotificationPreferencesEntity` com `fromJson`/`toJson` escritos à mão
 * (o projeto não usa `freezed`/`json_serializable`). Fica em `data/models/`
 * porque é a única camada que conhece o formato gravado no Firestore.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/notification_preferences_entity.dart';

/// Modelo de persistência de [NotificationPreferencesEntity].
class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({required super.values});

  /// Lê o mapa gravado no Firestore.
  ///
  /// Percorre o catálogo do domínio, e não as chaves do JSON: chave ausente cai
  /// no padrão e chave desconhecida é simplesmente ignorada. Assim um documento
  /// antigo continua abrindo a tela sem erro.
  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      values: {
        for (final preference in NotificationPreference.values)
          preference:
              json[preference.storageKey] as bool? ?? preference.defaultValue,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      for (final entry in values.entries) entry.key.storageKey: entry.value,
    };
  }
}
