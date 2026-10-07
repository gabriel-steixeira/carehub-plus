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
  /// **Segurança:** quem decide o acesso são as regras do Firestore — a
  /// dona ou quem tem concessão ativa para o assistido. Com perfil informado,
  /// a busca é pelo perfil (assim um assistido compartilhado mostra as
  /// tarefas de todos); sem perfil, só as tarefas da própria conta.
  Future<List<TaskModel>> fetchTasks({String? careRecipientId}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Você precisa estar autenticado para acessar as tarefas.',
      );
    }

    try {
      final query = careRecipientId != null && careRecipientId.isNotEmpty
          ? _firestore
                .collection('tasks')
                .where('careRecipientId', isEqualTo: careRecipientId)
          : _firestore
                .collection('tasks')
                .where('caregiverId', isEqualTo: user.uid);

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
  /// **Segurança:** ignora o `caregiverId` do modelo. A tarefa pertence
  /// sempre à dona do assistido (lida do próprio assistido), e `createdBy`
  /// guarda quem criou — assim uma pessoa convidada cria tarefas no perfil
  /// compartilhado. As regras do Firestore conferem as duas coisas.
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

    try {
      final finalTask = task.copyWith(
        id: docId,
        caregiverId: await _ownerOf(task.careRecipientId, fallback: user.uid),
      );
      await _firestore.collection('tasks').doc(docId).set({
        ...finalTask.toJson(),
        'createdBy': user.uid,
      });
      return finalTask;
    } on FirebaseException catch (error) {
      throw AppException(
        error.code == 'permission-denied'
            ? 'Seu acesso a este perfil não permite criar tarefas.'
            : 'Não foi possível salvar a tarefa. Tente novamente.',
        code: error.code,
      );
    }
  }

  /// Dona do assistido; [fallback] quando o perfil não pôde ser lido.
  Future<String> _ownerOf(
    String careRecipientId, {
    required String fallback,
  }) async {
    if (careRecipientId.isEmpty) return fallback;
    final recipient = await _firestore
        .collection('care_recipients')
        .doc(careRecipientId)
        .get();
    return (recipient.data()?['caregiverId'] as String?) ?? fallback;
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
