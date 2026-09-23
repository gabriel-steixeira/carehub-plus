import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/task_model.dart';

/// Repository for Tasks management with real Firebase Firestore integration.
class TasksRepository {
  TasksRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Busca as tarefas persistidas do cuidador autenticado, podendo limitar o
  /// resultado ao perfil cuidado informado. Uma coleção vazia é um estado
  /// válido, não um motivo para criar tarefas de exemplo.
  ///
  /// **Segurança:** Filtra SEMPRE pelo `caregiverId` do usuário logado para
  /// garantir que um cuidador nunca veja tarefas de outro cuidador, mesmo que
  /// ambos tenham perfis com o mesmo `careRecipientId`.
  Future<List<TaskModel>> fetchTasks({String? careRecipientId}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Você precisa estar autenticado para acessar as tarefas.',
      );
    }

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('tasks')
          .where('caregiverId', isEqualTo: user.uid);

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
  ///
  /// **Segurança:** Sempre define `caregiverId` como o UID do usuário logado,
  /// ignorando qualquer valor passado no modelo (proteção contra tentativa de
  /// criar tarefa para outro cuidador).
  Future<TaskModel> addTask(TaskModel task) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Você precisa estar autenticado para criar tarefas.',
      );
    }

    final docId = task.id.isEmpty
        ? 'task_${DateTime.now().millisecondsSinceEpoch}'
        : task.id;
    
    // Garante que a tarefa pertence ao cuidador logado
    final finalTask = task.copyWith(
      id: docId,
      caregiverId: user.uid,
    );

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
