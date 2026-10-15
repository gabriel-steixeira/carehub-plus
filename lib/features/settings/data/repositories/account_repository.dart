/*
 * CareHub Plus — Dados / Repositório da conta do cuidador
 *
 * Porta única do app para excluir a conta e para descobrir, antes de
 * confirmar, o impacto dessa exclusão. A exclusão em si roda no backend
 * (callable `deleteAccount`, com o login do Firebase); aqui só preparamos a
 * prévia lendo os perfis da dona e quem mais tem acesso a eles.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../services/cloud_functions_service.dart';
import '../../domain/entities/delete_account_preview.dart';

/// Exclusão da conta do cuidador e a prévia do impacto.
class AccountRepository {
  AccountRepository({
    CallableClient? client,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _client = client ?? CloudFunctionsService(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final CallableClient _client;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Analisa o impacto da exclusão para montar o aviso certo.
  ///
  /// Lê os perfis onde a conta é dona (`caregiverId == uid`). Se algum perfil
  /// tiver outra cuidadora com acesso (`accessUids` com um UID diferente do
  /// dono), o caso é [DeletionCase.ownerWithOthers] e os nomes dos afetados
  /// vêm de `network_members`. Sem outros com acesso, mas sendo dona de algum
  /// perfil, é [DeletionCase.ownerNoOthers]. Sem perfis próprios, é
  /// [DeletionCase.soloOrGrantee].
  Future<DeleteAccountPreview> resolveDeletionCase() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final ownedSnapshot = await _firestore
          .collection('care_recipients')
          .where('caregiverId', isEqualTo: uid)
          .get();

      if (ownedSnapshot.docs.isEmpty) {
        return const DeleteAccountPreview(
          deletionCase: DeletionCase.soloOrGrantee,
        );
      }

      final affectedNames = <String>[];
      var hasOtherAccess = false;

      for (final doc in ownedSnapshot.docs) {
        final data = doc.data();
        final accessUids = data['accessUids'];
        final othersWithAccess = accessUids is List
            ? accessUids
                .whereType<String>()
                .where((accessUid) => accessUid != uid)
                .toList()
            : const <String>[];

        if (othersWithAccess.isEmpty) continue;

        hasOtherAccess = true;
        affectedNames.addAll(await _affectedMemberNames(doc.id));
      }

      if (!hasOtherAccess) {
        return const DeleteAccountPreview(
          deletionCase: DeletionCase.ownerNoOthers,
        );
      }

      return DeleteAccountPreview(
        deletionCase: DeletionCase.ownerWithOthers,
        affectedNames: affectedNames,
      );
    } on FirebaseException catch (error) {
      throw AppException(
        error.message?.trim().isNotEmpty == true
            ? error.message!
            : 'Não foi possível verificar sua conta agora. Tente novamente.',
        code: error.code,
      );
    }
  }

  /// Nomes dos membros da rede de apoio de um perfil, para nomear os afetados.
  Future<List<String>> _affectedMemberNames(String careRecipientId) async {
    final snapshot = await _firestore
        .collection('network_members')
        .where('careRecipientId', isEqualTo: careRecipientId)
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['name'])
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();
  }

  /// Dispara a exclusão da conta e dos dados relacionados no backend.
  Future<void> deleteAccount() async {
    await _client.call('deleteAccount');
  }
}
