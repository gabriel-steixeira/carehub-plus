/*
 * CareHub Plus — Apresentação / Eventos do "Tenho um convite"
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

part of 'redeem_invite_bloc.dart';

abstract class RedeemInviteEvent extends Equatable {
  const RedeemInviteEvent();

  @override
  List<Object?> get props => [];
}

/// A pessoa tocou em "Usar convite" com o código digitado.
class RedeemInviteSubmittedEvent extends RedeemInviteEvent {
  const RedeemInviteSubmittedEvent({required this.code});

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Volta para o formulário (ex.: "usar outro código").
class RedeemInviteResetEvent extends RedeemInviteEvent {
  const RedeemInviteResetEvent();
}
