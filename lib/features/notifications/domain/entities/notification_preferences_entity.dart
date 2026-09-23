/*
 * CareHub Plus — Domínio / Preferências de Notificação do Cuidador
 *
 * Guarda o estado ligado/desligado de cada item de [NotificationPreference].
 * Optamos por um mapa em vez de um campo booleano por preferência: acrescentar
 * um alerta novo passa a ser uma linha no enum, sem mexer nesta classe, no
 * modelo nem no BLoC.
 *
 * Pertence ao Cuidador (dono da conta), não ao Cuidado: as preferências valem
 * para o aparelho de quem está logado, independente do perfil selecionado.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'notification_preference.dart';

/// Conjunto de preferências de notificação de um cuidador.
class NotificationPreferencesEntity extends Equatable {
  const NotificationPreferencesEntity({required this.values});

  /// Todas as preferências no valor padrão declarado no enum.
  factory NotificationPreferencesEntity.defaults() {
    return NotificationPreferencesEntity(
      values: {
        for (final preference in NotificationPreference.values)
          preference: preference.defaultValue,
      },
    );
  }

  /// Estado atual de cada preferência.
  final Map<NotificationPreference, bool> values;

  /// Estado de [preference], caindo no padrão quando a chave nunca foi gravada.
  bool isEnabled(NotificationPreference preference) {
    return values[preference] ?? preference.defaultValue;
  }

  /// Cópia com uma única preferência alterada.
  NotificationPreferencesEntity copyWithPreference(
    NotificationPreference preference,
    bool enabled,
  ) {
    return NotificationPreferencesEntity(
      values: {...values, preference: enabled},
    );
  }

  @override
  List<Object?> get props => [values];
}
