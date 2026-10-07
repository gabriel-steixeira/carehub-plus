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
