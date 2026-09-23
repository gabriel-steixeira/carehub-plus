/*
 * CareHub Plus — Dados / Modelo de Perfil do Cuidador
 *
 * Espelha `CaregiverProfileEntity` com `fromJson`/`toJson` escritos à mão (o
 * projeto não usa `freezed`/`json_serializable`). Só esta camada conhece o
 * formato do Firestore — `Timestamp`, chaves de campo e a chave de gênero.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/caregiver_gender.dart';
import '../../domain/entities/caregiver_profile_entity.dart';

/// Modelo de persistência de [CaregiverProfileEntity].
class CaregiverProfileModel extends CaregiverProfileEntity {
  const CaregiverProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.birthDate,
    super.gender,
    super.photoUrl,
    super.photoBase64,
  });

  /// Cria o modelo a partir do documento do Firestore.
  ///
  /// Campos ausentes viram `null`/vazio em vez de erro: documentos antigos
  /// foram gravados antes desta tela existir e não têm telefone, nascimento
  /// nem gênero.
  factory CaregiverProfileModel.fromJson(Map<String, dynamic> json) {
    return CaregiverProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: _asNonEmptyString(json['phone']),
      birthDate: _parseDate(json['birthDate']),
      gender: CaregiverGender.fromStorageKey(json['gender'] as String?),
      photoUrl: _asNonEmptyString(json['photoUrl']),
      photoBase64: _asNonEmptyString(json['photoBase64']),
    );
  }

  /// Cria o modelo a partir de uma entidade de domínio, para gravação.
  factory CaregiverProfileModel.fromEntity(CaregiverProfileEntity entity) {
    return CaregiverProfileModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      birthDate: entity.birthDate,
      gender: entity.gender,
      photoUrl: entity.photoUrl,
      photoBase64: entity.photoBase64,
    );
  }

  /// Mapa gravado no Firestore.
  ///
  /// Os campos editáveis vão sempre, mesmo `null`, porque apagar o telefone ou
  /// o gênero é uma edição legítima. A foto só entra quando existe: como a
  /// gravação usa `merge`, enviar `photoUrl: null` apagaria a foto atual.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate!),
      'gender': gender?.storageKey,
      if (hasPhoto && photoUrl != null) 'photoUrl': photoUrl,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      'updatedAt': Timestamp.now(),
    };
  }

  /// Aceita `Timestamp` (formato do Firestore), `DateTime` e texto ISO.
  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Texto vazio no banco significa "não informado".
  static String? _asNonEmptyString(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }
}
