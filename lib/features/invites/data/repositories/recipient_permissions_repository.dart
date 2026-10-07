/*
 * CareHub Plus — Dados / Permissões da conta num perfil
 *
 * Lê o espelho de acesso que o backend mantém no assistido
 * (`care_recipients/{id}.access.<uid>`) e diz se a conta logada pode editar
 * tarefas e usar o chat. Na dúvida (falha de leitura), libera: as regras do
 * Firestore continuam barrando o que não é permitido.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/recipient_permissions_entity.dart';

class RecipientPermissionsRepository {
  RecipientPermissionsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<RecipientPermissionsEntity> permissionsFor(
    String? careRecipientId,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || careRecipientId == null || careRecipientId.isEmpty) {
      return RecipientPermissionsEntity.full;
    }

    try {
      final doc = await _firestore
          .collection('care_recipients')
          .doc(careRecipientId)
          .get();
      return fromRecipientData(doc.data(), uid);
    } catch (_) {
      return RecipientPermissionsEntity.full;
    }
  }

  /// Regra pura (testável): dona → tudo; senão, conforme o nível espelhado.
  static RecipientPermissionsEntity fromRecipientData(
    Map<String, dynamic>? data,
    String uid,
  ) {
    if (data == null || data['caregiverId'] == uid) {
      return RecipientPermissionsEntity.full;
    }
    final access = data['access'];
    final grant = access is Map ? access[uid] : null;
    if (grant is! Map) return RecipientPermissionsEntity.full;

    final level = grant['level'];
    if (level == 'readonly') {
      return const RecipientPermissionsEntity(
        canEditTasks: false,
        canUseChat: false,
      );
    }
    if (level == 'partial') {
      final permissions = grant['permissions'];
      final granted = permissions is List
          ? permissions.whereType<String>().toSet()
          : const <String>{};
      return RecipientPermissionsEntity(
        canEditTasks: granted.contains('task'),
        canUseChat: granted.contains('chat'),
      );
    }
    return RecipientPermissionsEntity.full;
  }
}
