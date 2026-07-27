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
      title: 'Caminhada Leve na Praça',
      description: 'Realizar 20 minutos de caminhada monitorada.',
      scheduledTime: DateTime.now().subtract(const Duration(hours: 4)),
      category: TaskCategory.activity,
      frequency: TaskFrequency.daily,
      assignedToName: 'Maria Oliveira',
      isCompleted: false,
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
