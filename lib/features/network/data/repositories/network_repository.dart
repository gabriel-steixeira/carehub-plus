import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/network_member_model.dart';

/// Repository for managing the Support Network with real Firebase Firestore integration.
class NetworkRepository {
  NetworkRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _currentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        'Usuário não autenticado. Faça login novamente.',
      );
    }
    return user.uid;
  }

  /// Busca somente membros realmente cadastrados. Uma rede vazia é um estado
  /// válido e deve levar a interface a orientar o cadastro de um contato.
  ///
  /// Quando [careRecipientId] é informado, retorna apenas os membros
  /// vinculados àquele perfil cuidado. Registros antigos sem o campo
  /// `careRecipientId` ficam invisíveis no filtro — comportamento esperado,
  /// pois eles não pertencem a nenhum perfil específico.
  Future<List<NetworkMemberModel>> fetchMembers({
    String? careRecipientId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('network_members')
          .where('caregiverId', isEqualTo: _currentUserId());
      if (careRecipientId != null && careRecipientId.isNotEmpty) {
        query = query.where('careRecipientId', isEqualTo: careRecipientId);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((document) => NetworkMemberModel.fromJson(document.data()))
          .toList();
    } on FirebaseException catch (error) {
      throw AppException(
        'Não foi possível carregar a rede de apoio. Tente novamente.',
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'Não foi possível carregar a rede de apoio. Tente novamente.',
      );
    }
  }

  Future<NetworkMemberModel> addMember(NetworkMemberModel member) async {
    final docId = member.id.isEmpty
        ? 'mem_${DateTime.now().millisecondsSinceEpoch}'
        : member.id;
    final data = member.toJson();
    data['id'] = docId;
    data['caregiverId'] = _currentUserId();

    await _firestore.collection('network_members').doc(docId).set(data);
    return NetworkMemberModel.fromJson(data);
  }

  Future<NetworkMemberModel> updateMember(NetworkMemberModel member) async {
    final data = member.toJson();
    data['caregiverId'] = _currentUserId();
    await _firestore.collection('network_members').doc(member.id).set(data);
    return NetworkMemberModel.fromJson(data);
  }

  Future<void> removeMember(String memberId) async {
    await _firestore.collection('network_members').doc(memberId).delete();
  }
}
