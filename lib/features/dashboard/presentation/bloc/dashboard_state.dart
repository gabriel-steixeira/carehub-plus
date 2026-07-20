part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.caregiver,
    this.profiles = const [],
    this.selectedProfileId = '',
    this.summary,
    this.searchQuery = '',
    this.errorMessage,
  });

  final DashboardStatus status;
  final CaregiverModel? caregiver;
  final List<CareRecipientModel> profiles;
  final String selectedProfileId;
  final DashboardSummaryModel? summary;
  final String searchQuery;
  final String? errorMessage;

  CareRecipientModel? get selectedProfile {
    if (profiles.isEmpty) return null;
    return profiles.firstWhere(
      (p) => p.id == selectedProfileId,
      orElse: () => profiles.first,
    );
  }

  DashboardState copyWith({
    DashboardStatus? status,
    CaregiverModel? caregiver,
    List<CareRecipientModel>? profiles,
    String? selectedProfileId,
    DashboardSummaryModel? summary,
    String? searchQuery,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      caregiver: caregiver ?? this.caregiver,
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      summary: summary ?? this.summary,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        caregiver,
        profiles,
        selectedProfileId,
        summary,
        searchQuery,
        errorMessage,
      ];
}
