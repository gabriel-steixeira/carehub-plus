part of 'sos_bloc.dart';

abstract class SosEvent extends Equatable {
  const SosEvent();

  @override
  List<Object?> get props => [];
}

class SosLoadEvent extends SosEvent {
  const SosLoadEvent();
}

class SosTriggerAlertEvent extends SosEvent {
  const SosTriggerAlertEvent({this.location = 'São Paulo, SP'});

  final String location;

  @override
  List<Object?> get props => [location];
}

class SosCancelAlertEvent extends SosEvent {
  const SosCancelAlertEvent();
}
