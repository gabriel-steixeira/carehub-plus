import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

/// Repository for Chat functionality with real Firebase Firestore integration.
class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final List<ChatRoomModel> _seedRooms = [
    ChatRoomModel(
      id: 'room_1',
      title: 'Rede de Apoio — Vovó Lúcia',
      lastMessage: 'Medicação de pressão administrada às 08h.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 2,
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      careRecipientName: 'Vovó Lúcia',
    ),
    ChatRoomModel(
      id: 'room_2',
      title: 'Dr. Roberto (Cardiologista)',
      lastMessage: 'Receita enviada por email. Qualquer alteração me avisem.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      careRecipientName: 'Vovó Lúcia',
    ),
    ChatRoomModel(
      id: 'room_3',
      title: 'Cuidados da Yuna (Pet)',
      lastMessage: 'Ração da tarde servida!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      avatarUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=150',
      careRecipientName: 'Yuna',
    ),
  ];

  Future<List<ChatRoomModel>> fetchChatRooms() async {
    try {
      final snapshot = await _firestore.collection('chat_rooms').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => ChatRoomModel.fromJson(doc.data()))
            .toList();
      }

      // Seed initial rooms
      for (final room in _seedRooms) {
        await _firestore.collection('chat_rooms').doc(room.id).set(room.toJson());
      }
      return _seedRooms;
    } catch (_) {
      return _seedRooms;
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
