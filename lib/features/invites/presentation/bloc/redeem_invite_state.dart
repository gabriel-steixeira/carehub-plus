/*
 * CareHub Plus — Apresentação / Estado do "Tenho um convite"
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

part of 'redeem_invite_bloc.dart';

enum RedeemInviteStatus { initial, submitting, success, failure }

class RedeemInviteState extends Equatable {
  const RedeemInviteState({
    this.status = RedeemInviteStatus.initial,
    this.redeemed,
    this.errorMessage,
  });

  final RedeemInviteStatus status;

  /// Assistido liberado, quando [status] é `success`.
  final RedeemedInviteEntity? redeemed;
  final String? errorMessage;

  bool get isSubmitting => status == RedeemInviteStatus.submitting;

  RedeemInviteState copyWith({
    RedeemInviteStatus? status,
    RedeemedInviteEntity? redeemed,
    String? errorMessage,
  }) => RedeemInviteState(
    status: status ?? this.status,
    redeemed: redeemed ?? this.redeemed,
    // Erro só vale para o status em que foi emitido.
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, redeemed, errorMessage];
}
