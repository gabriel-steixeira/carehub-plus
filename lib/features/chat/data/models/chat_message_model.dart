import 'package:equatable/equatable.dart';

enum ChatMessageType { text, medicalNote, system }

/// Model representing an individual message in a chat room.
class ChatMessageModel extends Equatable {
  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isMe = false,
    this.type = ChatMessageType.text,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final ChatMessageType type;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderId = json['senderId'] as String;
    return ChatMessageModel(
      id: json['id'] as String,
      senderId: senderId,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMe: senderId == currentUserId,
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [id, senderId, senderName, text, timestamp, isMe, type];
}
