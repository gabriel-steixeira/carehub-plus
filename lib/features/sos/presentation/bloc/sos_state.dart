part of 'sos_bloc.dart';

enum SosStatus { initial, loading, success, failure }

class SosState extends Equatable {
  const SosState({
    this.status = SosStatus.initial,
    this.contacts = const [],
    this.protocols = const [],
    this.isTriggering = false,
    this.alertTriggered = false,
    this.errorMessage,
  });

  final SosStatus status;
  final List<EmergencyContactModel> contacts;
  final List<SosProtocolModel> protocols;
  final bool isTriggering;
  final bool alertTriggered;
  final String? errorMessage;

  SosState copyWith({
    SosStatus? status,
    List<EmergencyContactModel>? contacts,
    List<SosProtocolModel>? protocols,
    bool? isTriggering,
    bool? alertTriggered,
    String? errorMessage,
  }) {
    return SosState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      protocols: protocols ?? this.protocols,
      isTriggering: isTriggering ?? this.isTriggering,
      alertTriggered: alertTriggered ?? this.alertTriggered,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        contacts,
        protocols,
        isTriggering,
        alertTriggered,
        errorMessage,
      ];
}
