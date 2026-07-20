import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/emergency_contact_model.dart';
import '../../data/models/sos_protocol_model.dart';
import '../../data/repositories/sos_repository.dart';

part 'sos_event.dart';
part 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  SosBloc({required SosRepository repository})
      : _repository = repository,
        super(const SosState()) {
    on<SosLoadEvent>(_onLoad);
    on<SosTriggerAlertEvent>(_onTriggerAlert);
    on<SosCancelAlertEvent>(_onCancelAlert);
  }

  final SosRepository _repository;

  Future<void> _onLoad(
    SosLoadEvent event,
    Emitter<SosState> emit,
  ) async {
    emit(state.copyWith(status: SosStatus.loading));
    try {
      final contacts = await _repository.fetchContacts();
      final protocols = await _repository.fetchProtocols();
      emit(state.copyWith(
        status: SosStatus.success,
        contacts: contacts,
        protocols: protocols,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SosStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTriggerAlert(
    SosTriggerAlertEvent event,
    Emitter<SosState> emit,
  ) async {
    emit(state.copyWith(isTriggering: true));
    try {
      await _repository.triggerEmergencyAlert(location: event.location);
      emit(state.copyWith(
        isTriggering: false,
        alertTriggered: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTriggering: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCancelAlert(
    SosCancelAlertEvent event,
    Emitter<SosState> emit,
  ) {
    emit(state.copyWith(alertTriggered: false));
  }
}
