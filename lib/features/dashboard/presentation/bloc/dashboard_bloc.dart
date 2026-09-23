import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/models/caregiver_model.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/dashboard_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required DashboardRepository repository})
      : _repository = repository,
        super(const DashboardState()) {
    on<DashboardLoadEvent>(_onLoad);
    on<DashboardSelectProfileEvent>(_onSelectProfile);
    on<DashboardSearchQueryChangedEvent>(_onSearchQueryChanged);
  }

  final DashboardRepository _repository;

  Future<void> _onLoad(
    DashboardLoadEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final caregiver = await _repository.fetchCaregiver();
      final profiles = await _repository.fetchCareRecipients();

      final selectedId = event.selectedProfileId ??
          (profiles.isNotEmpty ? profiles.first.id : '');

      final summary = selectedId.isNotEmpty
          ? await _repository.fetchDashboardSummary(
              profileId: selectedId,
              monitoredProfilesCount: profiles.length,
            )
          : null;

      emit(state.copyWith(
        status: DashboardStatus.success,
        caregiver: caregiver,
        profiles: profiles,
        selectedProfileId: selectedId,
        summary: summary,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectProfile(
    DashboardSelectProfileEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.profileId == state.selectedProfileId) return;

    emit(state.copyWith(
      selectedProfileId: event.profileId,
      status: DashboardStatus.loading,
    ));

    try {
      final summary = await _repository.fetchDashboardSummary(
        profileId: event.profileId,
        monitoredProfilesCount: state.profiles.length,
      );
      emit(state.copyWith(
        status: DashboardStatus.success,
        summary: summary,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSearchQueryChanged(
    DashboardSearchQueryChangedEvent event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }
}
