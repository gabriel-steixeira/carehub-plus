import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_category.dart';
import '../models/task_frequency.dart';
import '../models/task_model.dart';

/// Repository for Tasks management with real Firebase Firestore integration.
class TasksRepository {
  TasksRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<TaskModel> _seedTasks = [
    TaskModel(
      id: 'task_1',
      careRecipientId: 'recipient_lucia',
      title: 'Comprar reposição de medicação AAS',
      description: 'Verificar estoque no armário e comprar na farmácia.',
      scheduledTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, 18, 0),
      category: TaskCategory.health,
      frequency: TaskFrequency.daily,
      assignedToName: 'Eu',
      isCompleted: false,
    ),
    TaskModel(
      id: 'task_2',
      careRecipientId: 'recipient_lucia',
      title: 'Dar janta',
      description: 'Servir refeição leve e sopa de legumes.',
      scheduledTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 30),
      category: TaskCategory.food,
      frequency: TaskFrequency.daily,
      assignedToName: 'JoJo',
      isCompleted: false,
    ),
    TaskModel(
      id: 'task_3',
      careRecipientId: 'recipient_lucia',
      title: 'Troca de Curativo',
      description: 'Limpar ferida com soro fisiológico e aplicar gaze limpa.',
      scheduledTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, 21, 0),
      category: TaskCategory.health,
      frequency: TaskFrequency.daily,
      assignedToName: 'Vitor',
      isCompleted: false,
    ),
  ];

  /// Fetches tasks for a specific care recipient or all if empty.
  Future<List<TaskModel>> fetchTasks({String? careRecipientId}) async {
    try {
      Query query = _firestore.collection('tasks');
      if (careRecipientId != null && careRecipientId.isNotEmpty) {
        query = query.where('careRecipientId', isEqualTo: careRecipientId);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      }

      // Seed default tasks into Firestore if collection is empty
      for (final task in _seedTasks) {
        await _firestore.collection('tasks').doc(task.id).set(task.toJson());
      }

      if (careRecipientId != null && careRecipientId.isNotEmpty) {
        return _seedTasks.where((t) => t.careRecipientId == careRecipientId).toList();
      }
      return _seedTasks;
    } catch (_) {
      if (careRecipientId != null && careRecipientId.isNotEmpty) {
        return _seedTasks.where((t) => t.careRecipientId == careRecipientId).toList();
      }
      return _seedTasks;
    }
  }

  /// Adds a new task to the Firestore repository.
  Future<TaskModel> addTask(TaskModel task) async {
    final docId = task.id.isEmpty
        ? 'task_${DateTime.now().millisecondsSinceEpoch}'
        : task.id;
    final finalTask = task.copyWith(id: docId);

    await _firestore.collection('tasks').doc(docId).set(finalTask.toJson());
    return finalTask;
  }

  /// Toggles task completion status with optional completion note.
  Future<TaskModel> toggleTaskCompletion(String taskId, {String? note}) async {
    final docRef = _firestore.collection('tasks').doc(taskId);
    final doc = await docRef.get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Tarefa não encontrada.');
    }

    final existing = TaskModel.fromJson(doc.data()!);
    final updated = existing.copyWith(
      isCompleted: !existing.isCompleted,
      completedAt: !existing.isCompleted ? DateTime.now() : null,
      completionNote: !existing.isCompleted ? note : null,
    );

    await docRef.update(updated.toJson());
    return updated;
  }

  /// Deletes a task by ID from Firestore.
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
}
