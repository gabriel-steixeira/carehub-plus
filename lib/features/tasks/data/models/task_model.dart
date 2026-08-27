import 'package:equatable/equatable.dart';

import 'task_frequency.dart';

/// Model representing a task/care item in CareHub+.
class TaskModel extends Equatable {
  const TaskModel({
    required this.id,
    required this.careRecipientId,
    required this.title,
    this.description = '',
    required this.scheduledTime,
    this.categoryId = 'other',
    this.frequency = TaskFrequency.once,
    this.assignedToName,
    this.assignedToMemberId,
    this.assignedToPhotoUrl,
    this.isCompleted = false,
    this.completedAt,
    this.completionNote,
  });

  final String id;
  final String careRecipientId;
  final String title;
  final String description;
  final DateTime scheduledTime;

  /// Id de uma `CareCategoryEntity` (feature `categories/`, compartilhada com
  /// o Chat). Guardado como string — e não como enum — para que novas
  /// categorias criadas pela cuidadora não exijam alterar este modelo.
  final String categoryId;
  final TaskFrequency frequency;
  final String? assignedToName;
  final String? assignedToMemberId;
  final String? assignedToPhotoUrl;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completionNote;

  bool get isOverdue => !isCompleted && scheduledTime.isBefore(DateTime.now());

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      careRecipientId: json['careRecipientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      categoryId:
          json['categoryId'] as String? ??
          json['category'] as String? ??
          'other',
      frequency: TaskFrequency.fromValue(
        json['frequency'] as String? ?? 'once',
      ),
      assignedToName: json['assignedToName'] as String?,
      assignedToMemberId: json['assignedToMemberId'] as String?,
      assignedToPhotoUrl: json['assignedToPhotoUrl'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      completionNote: json['completionNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'careRecipientId': careRecipientId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'categoryId': categoryId,
      'frequency': frequency.value,
      'assignedToName': assignedToName,
      'assignedToMemberId': assignedToMemberId,
      'assignedToPhotoUrl': assignedToPhotoUrl,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'completionNote': completionNote,
    };
  }

  TaskModel copyWith({
    String? id,
    String? careRecipientId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? categoryId,
    TaskFrequency? frequency,
    String? assignedToName,
    String? assignedToMemberId,
    String? assignedToPhotoUrl,
    bool? isCompleted,
    DateTime? completedAt,
    String? completionNote,
  }) {
    return TaskModel(
      id: id ?? this.id,
      careRecipientId: careRecipientId ?? this.careRecipientId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToMemberId: assignedToMemberId ?? this.assignedToMemberId,
      assignedToPhotoUrl: assignedToPhotoUrl ?? this.assignedToPhotoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completionNote: completionNote ?? this.completionNote,
    );
  }

  @override
  List<Object?> get props => [
    id,
    careRecipientId,
    title,
    description,
    scheduledTime,
    categoryId,
    frequency,
    assignedToName,
    assignedToMemberId,
    assignedToPhotoUrl,
    isCompleted,
    completedAt,
    completionNote,
  ];
}
