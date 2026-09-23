/*
 * CareHub Plus — Domínio / Conteúdo Sobre
 *
 * Representa o conteúdo institucional exibido na página Sobre. A entidade é
 * independente do Firebase para que a apresentação renderize somente dados já
 * carregados pelo fluxo da feature.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Conteúdo institucional público para usuários autenticados.
class AboutContentEntity extends Equatable {
  const AboutContentEntity({
    required this.appName,
    required this.version,
    required this.title,
    required this.description,
    this.updatedAt,
  });

  final String appName;
  final String version;
  final String title;
  final String description;
  final DateTime? updatedAt;

  /// Indica se há texto suficiente para renderizar a página.
  bool get hasContent =>
      title.trim().isNotEmpty && description.trim().isNotEmpty;

  @override
  List<Object?> get props => [appName, version, title, description, updatedAt];
}
