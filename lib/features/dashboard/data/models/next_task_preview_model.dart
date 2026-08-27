/*
 * CareHub Plus — Data / Next Task Preview Model
 *
 * Projeção mínima de uma tarefa usada exclusivamente no Dashboard para exibir
 * a próxima tarefa pendente do dia sem importar o TaskModel completo.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Projeção leve de uma tarefa para o card "Próxima Tarefa" do Dashboard.
///
/// Contém apenas os campos necessários para renderizar o card — título,
/// horário agendado e categoria — sem acoplar o Dashboard ao [TaskModel]
/// completo da feature `tasks/`.
class NextTaskPreviewModel extends Equatable {
  const NextTaskPreviewModel({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.categoryId = 'other',
    this.assignedToName,
  });

  final String id;
  final String title;
  final DateTime scheduledTime;
  final String categoryId;
  final String? assignedToName;

  factory NextTaskPreviewModel.fromJson(Map<String, dynamic> json) {
    return NextTaskPreviewModel(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      categoryId: json['categoryId'] as String? ?? 'other',
      assignedToName: json['assignedToName'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, scheduledTime, categoryId, assignedToName];
}
