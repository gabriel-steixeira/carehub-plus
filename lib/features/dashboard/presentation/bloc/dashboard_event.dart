part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoadEvent extends DashboardEvent {
  const DashboardLoadEvent({this.selectedProfileId});

  final String? selectedProfileId;

  @override
  List<Object?> get props => [selectedProfileId];
}

class DashboardSelectProfileEvent extends DashboardEvent {
  const DashboardSelectProfileEvent({required this.profileId});

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

class DashboardSearchQueryChangedEvent extends DashboardEvent {
  const DashboardSearchQueryChangedEvent({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}
