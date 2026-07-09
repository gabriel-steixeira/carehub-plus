import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/caregiver_model.dart';
import '../../data/models/care_recipient_model.dart';
import '../../data/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required HomeRepository repository})
      : _repository = repository,
        super(const HomeState()) {
    on<HomeLoadEvent>(_onLoad);
    on<HomeSelectProfileEvent>(_onSelectProfile);
  }

  final HomeRepository _repository;

  Future<void> _onLoad(
    HomeLoadEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final caregiver = await _repository.fetchCaregiver();
      final profiles = await _repository.fetchCareRecipients();
      emit(state.copyWith(
        status: HomeStatus.success,
        caregiver: caregiver,
        profiles: profiles,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSelectProfile(
    HomeSelectProfileEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedProfileId: event.profileId));
  }
}
