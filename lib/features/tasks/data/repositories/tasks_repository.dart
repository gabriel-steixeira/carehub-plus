import '../models/task_category.dart';
import '../models/task_frequency.dart';
import '../models/task_model.dart';

/// Repository for Tasks management.
class TasksRepository {
  final List<TaskModel> _mockTasks = [
    TaskModel(
      id: 'task_1',
      careRecipientId: 'recipient_lucia',
      title: 'Anti-hipertensivo (Losartana 50mg)',
      description: 'Tomar 1 comprimido com água após o café da manhã.',
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      category: TaskCategory.medication,
      frequency: TaskFrequency.daily,
      assignedToName: 'Maria Oliveira',
      isCompleted: false,
    ),
    TaskModel(
      id: 'task_2',
      careRecipientId: 'recipient_lucia',
      title: 'Aferir Pressão Arterial',
      description: 'Anotar sístole e diástole no diário de saúde.',
      scheduledTime: DateTime.now().subtract(const Duration(hours: 2)),
      category: TaskCategory.appointment,
      frequency: TaskFrequency.daily,
      assignedToName: 'Patrícia (Cuidadora)',
      isCompleted: true,
      completedAt: DateTime.now().subtract(const Duration(hours: 1)),
      completionNote: 'Pressão 12/8 - Dentro do normal.',
    ),
    TaskModel(
      id: 'task_3',
      careRecipientId: 'recipient_lucia',
      title: 'Caminhada Leve no Praça',
      description: 'Realizar 20 minutos de caminhada monitorada.',
      scheduledTime: DateTime.now().subtract(const Duration(hours: 4)),
      category: TaskCategory.activity,
      frequency: TaskFrequency.daily,
      assignedToName: 'Maria Oliveira',
      isCompleted: false, // Overdue
    ),
    TaskModel(
      id: 'task_4',
      careRecipientId: 'recipient_yuna',
      title: 'Ração Sênior + Suplemento',
      description: 'Servir 150g de ração com a vitamina de articulações.',
      scheduledTime: DateTime.now().add(const Duration(hours: 3)),
      category: TaskCategory.food,
      frequency: TaskFrequency.daily,
      assignedToName: 'Maria Oliveira',
      isCompleted: false,
    ),
  ];

  /// Fetches tasks for a specific care recipient or all if empty.
  Future<List<TaskModel>> fetchTasks({String? careRecipientId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (careRecipientId == null || careRecipientId.isEmpty) {
      return List.unmodifiable(_mockTasks);
    }
    return _mockTasks
        .where((t) => t.careRecipientId == careRecipientId)
        .toList();
  }

  /// Adds a new task to the repository.
  Future<TaskModel> addTask(TaskModel task) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockTasks.insert(0, task);
    return task;
  }

  /// Toggles task completion status with optional completion note.
  Future<TaskModel> toggleTaskCompletion(String taskId, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw Exception('Tarefa não encontrada.');
    }
    final existing = _mockTasks[index];
    final updated = existing.copyWith(
      isCompleted: !existing.isCompleted,
      completedAt: !existing.isCompleted ? DateTime.now() : null,
      completionNote: !existing.isCompleted ? note : null,
    );
    _mockTasks[index] = updated;
    return updated;
  }

  /// Deletes a task by ID.
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockTasks.removeWhere((t) => t.id == taskId);
  }
}
