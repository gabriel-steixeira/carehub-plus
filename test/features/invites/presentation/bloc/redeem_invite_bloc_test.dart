/*
 * CareHub Plus — Testes / BLoC "Tenho um convite"
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/invites/data/repositories/invites_repository.dart';
import 'package:carehub_plus/features/invites/domain/entities/redeemed_invite_entity.dart';
import 'package:carehub_plus/features/invites/presentation/bloc/redeem_invite_bloc.dart';
import 'package:carehub_plus/services/selected_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvitesRepository extends Mock implements InvitesRepository {}

class MockSelectedProfileService extends Mock
    implements SelectedProfileService {}

const _redeemed = RedeemedInviteEntity(
  careRecipientId: 'r1',
  careRecipientName: 'Lúcia',
);

void main() {
  late MockInvitesRepository repository;
  late MockSelectedProfileService profiles;

  setUp(() {
    repository = MockInvitesRepository();
    profiles = MockSelectedProfileService();
    when(
      () => profiles.setSelectedProfile(
        careRecipientId: any(named: 'careRecipientId'),
        careRecipientName: any(named: 'careRecipientName'),
      ),
    ).thenAnswer((_) async {});
  });

  RedeemInviteBloc build() => RedeemInviteBloc(
    repository: repository,
    profileServiceFactory: () async => profiles,
  );

  blocTest<RedeemInviteBloc, RedeemInviteState>(
    'emits [failure] without calling the backend when the code is incomplete',
    build: build,
    act: (bloc) => bloc.add(const RedeemInviteSubmittedEvent(code: '7F3')),
    expect: () => [
      const RedeemInviteState(
        status: RedeemInviteStatus.failure,
        errorMessage: 'Digite os 6 caracteres do código.',
      ),
    ],
    verify: (_) => verifyNever(() => repository.redeemCode(any())),
  );

  blocTest<RedeemInviteBloc, RedeemInviteState>(
    'emits [submitting, success], normalizes the code and selects the profile',
    build: () {
      when(
        () => repository.redeemCode('7F3K9Q'),
      ).thenAnswer((_) async => _redeemed);
      return build();
    },
    act: (bloc) => bloc.add(const RedeemInviteSubmittedEvent(code: ' 7f3-k9q ')),
    expect: () => [
      const RedeemInviteState(status: RedeemInviteStatus.submitting),
      const RedeemInviteState(
        status: RedeemInviteStatus.success,
        redeemed: _redeemed,
      ),
    ],
    verify: (_) => verify(
      () => profiles.setSelectedProfile(
        careRecipientId: 'r1',
        careRecipientName: 'Lúcia',
      ),
    ).called(1),
  );

  blocTest<RedeemInviteBloc, RedeemInviteState>(
    'emits [submitting, failure] with the backend message',
    build: () {
      when(() => repository.redeemCode(any())).thenThrow(
        const AppException(
          'Código inválido ou vencido. Peça um novo convite.',
          code: 'not-found',
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(const RedeemInviteSubmittedEvent(code: 'ZZZZZZ')),
    expect: () => [
      const RedeemInviteState(status: RedeemInviteStatus.submitting),
      const RedeemInviteState(
        status: RedeemInviteStatus.failure,
        errorMessage: 'Código inválido ou vencido. Peça um novo convite.',
      ),
    ],
  );

  blocTest<RedeemInviteBloc, RedeemInviteState>(
    'still succeeds when saving the selected profile fails',
    build: () {
      when(
        () => repository.redeemCode(any()),
      ).thenAnswer((_) async => _redeemed);
      return RedeemInviteBloc(
        repository: repository,
        profileServiceFactory: () async => throw Exception('prefs'),
      );
    },
    act: (bloc) => bloc.add(const RedeemInviteSubmittedEvent(code: '7F3K9Q')),
    expect: () => [
      const RedeemInviteState(status: RedeemInviteStatus.submitting),
      const RedeemInviteState(
        status: RedeemInviteStatus.success,
        redeemed: _redeemed,
      ),
    ],
  );

  blocTest<RedeemInviteBloc, RedeemInviteState>(
    'reset goes back to the form',
    build: build,
    seed: () => const RedeemInviteState(
      status: RedeemInviteStatus.success,
      redeemed: _redeemed,
    ),
    act: (bloc) => bloc.add(const RedeemInviteResetEvent()),
    expect: () => [const RedeemInviteState()],
  );
}
