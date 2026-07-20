part of 'tasks_bloc.dart';

abstract class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoadEvent extends TasksEvent {
  const TasksLoadEvent({this.careRecipientId});

  final String? careRecipientId;

  @override
  List<Object?> get props => [careRecipientId];
}

class TasksFilterChangedEvent extends TasksEvent {
  const TasksFilterChangedEvent({required this.filterTab});

  final String filterTab; // 'all', 'today', 'completed', 'overdue'

  @override
  List<Object?> get props => [filterTab];
}

class TasksCategoryFilterChangedEvent extends TasksEvent {
  const TasksCategoryFilterChangedEvent({this.category});

  final TaskCategory? category;

  @override
  List<Object?> get props => [category];
}

class TaskCreateEvent extends TasksEvent {
  const TaskCreateEvent({
    required this.careRecipientId,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.category,
    required this.frequency,
    this.assignedToName,
  });

  final String careRecipientId;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final TaskCategory category;
  final TaskFrequency frequency;
  final String? assignedToName;

  @override
  List<Object?> get props => [
        careRecipientId,
        title,
        description,
        scheduledTime,
        category,
        frequency,
        assignedToName,
      ];
}

class TaskToggleCompletionEvent extends TasksEvent {
  const TaskToggleCompletionEvent({required this.taskId, this.note});

  final String taskId;
  final String? note;

  @override
  List<Object?> get props => [taskId, note];
}

class TaskDeleteEvent extends TasksEvent {
  const TaskDeleteEvent({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}
