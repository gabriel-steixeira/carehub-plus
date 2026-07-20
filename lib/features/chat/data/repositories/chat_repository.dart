import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

/// Repository for Chat functionality across support network members.
class ChatRepository {
  final List<ChatRoomModel> _mockRooms = [
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

  final Map<String, List<ChatMessageModel>> _mockMessages = {
    'room_1': [
      ChatMessageModel(
        id: 'msg_1',
        senderId: 'user_patricia',
        senderName: 'Patrícia (Cuidadora)',
        text: 'Bom dia! Vovó Lúcia acordou bem disposta hoje.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isMe: false,
      ),
      ChatMessageModel(
        id: 'msg_2',
        senderId: 'user_me',
        senderName: 'Você',
        text: 'Ótimo noticia! Ela tomou a medicação matinal?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: true,
      ),
      ChatMessageModel(
        id: 'msg_3',
        senderId: 'user_patricia',
        senderName: 'Patrícia (Cuidadora)',
        text: 'Sim, medicação de pressão administrada às 08h. Pressão 12/8.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        isMe: false,
        type: ChatMessageType.medicalNote,
      ),
    ],
  };

  Future<List<ChatRoomModel>> fetchChatRooms() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_mockRooms);
  }

  Future<List<ChatMessageModel>> fetchMessages(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockMessages[roomId] ?? [];
  }

  Future<ChatMessageModel> sendMessage(
    String roomId,
    String text, {
    ChatMessageType type = ChatMessageType.text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final newMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user_me',
      senderName: 'Você',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      type: type,
    );

    if (!_mockMessages.containsKey(roomId)) {
      _mockMessages[roomId] = [];
    }
    _mockMessages[roomId]!.add(newMsg);

    return newMsg;
  }
}
