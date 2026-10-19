part of 'sos_detail_bloc.dart';

abstract class SosDetailEvent extends Equatable {
  const SosDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega os detalhes do pedido de ajuda identificado por [alertId].
class SosDetailLoadRequested extends SosDetailEvent {
  const SosDetailLoadRequested(this.alertId);

  final String alertId;

  @override
  List<Object?> get props => [alertId];
}

/// A pessoa acionada toca em "Estou a caminho" e aceita o pedido.
class SosDetailAcceptRequested extends SosDetailEvent {
  const SosDetailAcceptRequested();
}
