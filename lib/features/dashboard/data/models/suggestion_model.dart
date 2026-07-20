import 'package:equatable/equatable.dart';

/// Model for AI (Cora) pro-active suggestions shown in Dashboard.
class SuggestionModel extends Equatable {
  const SuggestionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.category = 'dica',
    this.iconName,
  });

  final String id;
  final String title;
  final String description;
  final String actionLabel;
  final String category;
  final String? iconName;

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionLabel: json['actionLabel'] as String? ?? 'Ver detalhes',
      category: json['category'] as String? ?? 'dica',
      iconName: json['iconName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actionLabel': actionLabel,
      'category': category,
      'iconName': iconName,
    };
  }

  @override
  List<Object?> get props => [id, title, description, actionLabel, category, iconName];
}
