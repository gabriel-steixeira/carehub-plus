import 'package:equatable/equatable.dart';

/// Model representing a message in the Cora AI Assistant chat.
class CoraMessageModel extends Equatable {
  const CoraMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies = const [],
    this.actionRoute,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> quickReplies;
  final String? actionRoute;

  @override
  List<Object?> get props => [
        id,
        text,
        isUser,
        timestamp,
        quickReplies,
        actionRoute,
      ];
}
