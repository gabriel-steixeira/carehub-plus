/*
 * CareHub Plus — Dados / Modelo de Conteúdo Sobre
 *
 * Converte manualmente o documento institucional do Firestore para a entidade
 * usada pela página Sobre. O projeto não utiliza geração de código para modelos.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/about_content_entity.dart';

/// Modelo serializável do conteúdo institucional.
class AboutContentModel extends AboutContentEntity {
  const AboutContentModel({
    required super.appName,
    required super.version,
    required super.title,
    required super.description,
    super.updatedAt,
  });

  factory AboutContentModel.fromJson(Map<String, dynamic> json) {
    return AboutContentModel(
      appName: json['appName'] as String? ?? 'CareHub+',
      version: json['version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'version': version,
      'title': title,
      'description': description,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
