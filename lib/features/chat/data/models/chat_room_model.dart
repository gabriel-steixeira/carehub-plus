import 'package:equatable/equatable.dart';

/// Palavras-chave usadas para inferir a categoria de assuntos antigos, salvos
/// no Firestore antes de `categoryId` existir. Novos assuntos sempre nascem
/// com `categoryId` explícito (ver `CreateChatRoomBottomSheet`).
const _legacyFoodKeywords = [
  'ração',
  'aliment',
  'cardápio',
  'comida',
  'refeição',
];

/// Model representing a conversation channel/room in CareHub+.
class ChatRoomModel extends Equatable {
  const ChatRoomModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
    this.careRecipientName,
    this.careRecipientId,
    this.categoryId = 'health',
    this.responsibleMemberId,
    this.responsibleMemberName,
    this.responsibleMemberPhotoUrl,
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  /// Foto de quem enviou a última mensagem — usada no cartão de identidade
  /// da sala (`ChatRoomPage`), no lugar do avatar fixo de um assistente.
  final String? avatarUrl;
  final String? careRecipientName;

  /// FK para o perfil cuidado — permite filtrar salas por Care Recipient.
  /// Nulo em salas criadas antes deste campo existir (retrocompatível).
  final String? careRecipientId;

  /// Id de uma `CareCategoryEntity` (feature `categories/`, compartilhada
  /// com Tasks).
  final String categoryId;
  final String? responsibleMemberId;
  final String? responsibleMemberName;
  final String? responsibleMemberPhotoUrl;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final lastMessage = json['lastMessage'] as String;

    return ChatRoomModel(
      id: json['id'] as String,
      title: title,
      lastMessage: lastMessage,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      careRecipientName: json['careRecipientName'] as String?,
      careRecipientId: json['careRecipientId'] as String?,
      // Assuntos salvos antes de existir `categoryId` são inferidos por
      // palavra-chave, para não ficarem sem categoria depois da migração.
      categoryId:
          json['categoryId'] as String? ??
          _inferLegacyCategoryId(title, lastMessage),
      responsibleMemberId: json['responsibleMemberId'] as String?,
      responsibleMemberName: json['responsibleMemberName'] as String?,
      responsibleMemberPhotoUrl: json['responsibleMemberPhotoUrl'] as String?,
    );
  }

  static String _inferLegacyCategoryId(String title, String lastMessage) {
    final content = '$title $lastMessage'.toLowerCase();
    return _legacyFoodKeywords.any(content.contains) ? 'food' : 'health';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
      'careRecipientName': careRecipientName,
      'careRecipientId': careRecipientId,
      'categoryId': categoryId,
      'responsibleMemberId': responsibleMemberId,
      'responsibleMemberName': responsibleMemberName,
      'responsibleMemberPhotoUrl': responsibleMemberPhotoUrl,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    String? title,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? avatarUrl,
    String? careRecipientName,
    String? careRecipientId,
    String? categoryId,
    String? responsibleMemberId,
    String? responsibleMemberName,
    String? responsibleMemberPhotoUrl,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      careRecipientName: careRecipientName ?? this.careRecipientName,
      careRecipientId: careRecipientId ?? this.careRecipientId,
      categoryId: categoryId ?? this.categoryId,
      responsibleMemberId: responsibleMemberId ?? this.responsibleMemberId,
      responsibleMemberName:
          responsibleMemberName ?? this.responsibleMemberName,
      responsibleMemberPhotoUrl:
          responsibleMemberPhotoUrl ?? this.responsibleMemberPhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    lastMessage,
    lastMessageTime,
    unreadCount,
    avatarUrl,
    careRecipientName,
    careRecipientId,
    categoryId,
    responsibleMemberId,
    responsibleMemberName,
    responsibleMemberPhotoUrl,
  ];
}
