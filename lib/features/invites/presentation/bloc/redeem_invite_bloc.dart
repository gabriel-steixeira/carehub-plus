/*
 * CareHub Plus — Apresentação / BLoC "Tenho um convite"
 *
 * Valida o formato do código, pede ao backend para aceitar o convite e, no
 * sucesso, deixa o assistido compartilhado selecionado para a pessoa já
 * cair nele ao voltar para o início.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../services/selected_profile_service.dart';
import '../../data/repositories/invites_repository.dart';
import '../../domain/entities/redeemed_invite_entity.dart';

part 'redeem_invite_event.dart';
part 'redeem_invite_state.dart';

/// Tamanho do código gerado pelo backend.
const int inviteCodeLength = 6;

class RedeemInviteBloc extends Bloc<RedeemInviteEvent, RedeemInviteState> {
  RedeemInviteBloc({
    required InvitesRepository repository,
    Future<SelectedProfileService> Function()? profileServiceFactory,
  }) : _repository = repository,
       _profileServiceFactory =
           profileServiceFactory ?? SelectedProfileService.create,
       super(const RedeemInviteState()) {
    on<RedeemInviteSubmittedEvent>(_onSubmitted);
    on<RedeemInviteResetEvent>((_, emit) => emit(const RedeemInviteState()));
  }

  final InvitesRepository _repository;
  final Future<SelectedProfileService> Function() _profileServiceFactory;

  /// Mesma limpeza do backend: maiúsculas, só letras e números.
  static String normalize(String raw) =>
      raw.toUpperCase().replaceAll(RegExp('[^0-9A-Z]'), '');

  Future<void> _onSubmitted(
    RedeemInviteSubmittedEvent event,
    Emitter<RedeemInviteState> emit,
  ) async {
    final code = normalize(event.code);
    if (code.length != inviteCodeLength) {
      emit(
        state.copyWith(
          status: RedeemInviteStatus.failure,
          errorMessage: 'Digite os $inviteCodeLength caracteres do código.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: RedeemInviteStatus.submitting));
    try {
      final redeemed = await _repository.redeemCode(code);
      // Materializa o vínculo no backend agora (grava `accessUids`), para o
      // assistido compartilhado já aparecer na Home sem precisar de novo login.
      // Idempotente: se falhar, o acesso recém-resgatado continua valendo.
      await _claimAfterRedeem();
      await _selectProfile(redeemed);
      emit(
        RedeemInviteState(
          status: RedeemInviteStatus.success,
          redeemed: redeemed,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: RedeemInviteStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Garante que o convite recém-resgatado já esteja reivindicado no backend.
  ///
  /// A Home lista os compartilhados pelo campo `accessUids` do assistido, que
  /// é gravado pela função `claimPendingInvites`. Sem esta chamada, o vínculo
  /// só era materializado no próximo login. É conveniência: uma falha aqui não
  /// invalida o resgate, então o sucesso é preservado.
  Future<void> _claimAfterRedeem() async {
    try {
      await _repository.claimPendingInvites();
    } catch (_) {}
  }

  /// Seleção é conveniência: se falhar, o acesso continua valendo.
  Future<void> _selectProfile(RedeemedInviteEntity redeemed) async {
    try {
      final profiles = await _profileServiceFactory();
      await profiles.setSelectedProfile(
        careRecipientId: redeemed.careRecipientId,
        careRecipientName: redeemed.careRecipientName,
      );
    } catch (_) {}
  }
}
