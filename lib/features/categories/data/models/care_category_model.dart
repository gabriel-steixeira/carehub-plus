/*
 * CareHub Plus — Dados / Modelo de Categoria de Cuidado
 *
 * Espelha `CareCategoryEntity` com `fromJson`/`toJson` escritos à mão (o
 * projeto não usa `freezed`/`json_serializable`). Fica em `data/models/`
 * porque conhece o formato do Firestore; a apresentação depende só da
 * entidade de domínio.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../domain/entities/care_category_entity.dart';

/// Modelo de persistência de [CareCategoryEntity].
class CareCategoryModel extends CareCategoryEntity {
  const CareCategoryModel({
    required super.id,
    required super.label,
    required super.iconKey,
    required super.colorKey,
    super.isDefault = false,
  });

  factory CareCategoryModel.fromJson(Map<String, dynamic> json) {
    return CareCategoryModel(
      id: json['id'] as String,
      label: json['label'] as String,
      iconKey: json['iconKey'] as String? ?? 'other',
      colorKey: json['colorKey'] as String? ?? 'grey',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'iconKey': iconKey,
      'colorKey': colorKey,
      'isDefault': isDefault,
    };
  }
}
