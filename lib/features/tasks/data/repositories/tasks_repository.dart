import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/task_model.dart';

/// Repository for Tasks management with real Firebase Firestore integration.
class TasksRepository {
  TasksRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Busca as tarefas persistidas, podendo limitar o resultado ao perfil
  /// cuidado informado. Uma coleção vazia é um estado válido, não um motivo
  /// para criar tarefas de exemplo.
  Future<List<TaskModel>> fetchTasks({String? careRecipientId}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('tasks');
      if (careRecipientId != null && careRecipientId.isNotEmpty) {
        query = query.where('careRecipientId', isEqualTo: careRecipientId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((document) => TaskModel.fromJson(document.data()))
          .toList();
    } on FirebaseException catch (error) {
      throw AppException(
        'Não foi possível carregar as tarefas. Tente novamente.',
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'Não foi possível carregar as tarefas. Tente novamente.',
      );
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
