import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

/// Repository for Chat functionality with real Firebase Firestore integration.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Busca exclusivamente as salas persistidas na coleção `chat_rooms`.
  ///
  /// Salas antigas sem o campo `careRecipientId` não aparecem no filtro —
  /// comportamento esperado enquanto a migração não for concluída.
  Future<List<ChatRoomModel>> fetchChatRooms({String? careRecipientId}) async {
    if (careRecipientId == null || careRecipientId.isEmpty) {
      return const [];
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('chat_rooms');
      if (careRecipientId.isNotEmpty) {
        query = query.where('careRecipientId', isEqualTo: careRecipientId);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw AppException(
        e.message ?? 'Erro ao carregar os assuntos.',
        code: e.code,
      );
    }
  }

  /// Cria um novo assunto (sala de conversa) para um Care Recipient.
  Future<ChatRoomModel> addRoom({
    required String careRecipientId,
    required String title,
    required String careRecipientName,
    required String categoryId,
    String? avatarUrl,
    String? responsibleMemberId,
    String? responsibleMemberName,
    String? responsibleMemberPhotoUrl,
  }) async {
    final id = 'room_${DateTime.now().millisecondsSinceEpoch}';
    final room = ChatRoomModel(
      id: id,
      title: title,
      lastMessage: 'Assunto criado.',
      lastMessageTime: DateTime.now(),
      careRecipientName: careRecipientName,
      careRecipientId: careRecipientId,
      categoryId: categoryId,
      avatarUrl: avatarUrl,
      responsibleMemberId: responsibleMemberId,
      responsibleMemberName: responsibleMemberName,
      responsibleMemberPhotoUrl: responsibleMemberPhotoUrl,
    );

    try {
      await _firestore.collection('chat_rooms').doc(id).set(room.toJson());
      return room;
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Erro ao criar assunto.', code: e.code);
    }
  }

  Future<List<ChatMessageModel>> fetchMessages(String roomId) async {
    final uid = _auth.currentUser?.uid ?? 'user_me';
    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => ChatMessageModel.fromJson(doc.data(), uid))
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ChatMessageModel> sendMessage(
    String roomId,
    String text, {
    ChatMessageType type = ChatMessageType.text,
  }) async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? 'user_me';
    final name = user?.displayName ?? 'Você';
    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    final newMsg = ChatMessageModel(
      id: msgId,
      senderId: uid,
      senderName: name,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      type: type,
    );

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(msgId)
          .set(newMsg.toJson());

      await _firestore.collection('chat_rooms').doc(roomId).update({
        'lastMessage': text,
        'lastMessageTime': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return newMsg;
  }
}
