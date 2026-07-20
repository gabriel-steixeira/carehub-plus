import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? avatarUrl;
  final String? careRecipientName;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      title: json['title'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      careRecipientName: json['careRecipientName'] as String?,
    );
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
    };
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
      ];
}
