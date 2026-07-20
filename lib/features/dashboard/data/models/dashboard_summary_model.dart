import 'package:equatable/equatable.dart';
import 'suggestion_model.dart';

/// Model representing summary statistics and suggestions for the Dashboard.
class DashboardSummaryModel extends Equatable {
  const DashboardSummaryModel({
    required this.monitoredProfilesCount,
    required this.pendingTasksCount,
    required this.supportNetworkCount,
    required this.unreadChatsCount,
    this.suggestions = const [],
  });

  final int monitoredProfilesCount;
  final int pendingTasksCount;
  final int supportNetworkCount;
  final int unreadChatsCount;
  final List<SuggestionModel> suggestions;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      monitoredProfilesCount: json['monitoredProfilesCount'] as int? ?? 0,
      pendingTasksCount: json['pendingTasksCount'] as int? ?? 0,
      supportNetworkCount: json['supportNetworkCount'] as int? ?? 0,
      unreadChatsCount: json['unreadChatsCount'] as int? ?? 0,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monitoredProfilesCount': monitoredProfilesCount,
      'pendingTasksCount': pendingTasksCount,
      'supportNetworkCount': supportNetworkCount,
      'unreadChatsCount': unreadChatsCount,
      'suggestions': suggestions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        monitoredProfilesCount,
        pendingTasksCount,
        supportNetworkCount,
        unreadChatsCount,
        suggestions,
      ];
}
