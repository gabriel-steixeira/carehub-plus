/*
 * CareHub Plus — Testes / Convite no cadastro da rede de apoio
 *
 * O membro é salvo antes do convite (o backend lê o prazo do documento).
 * Falha no convite não desfaz o membro. Revogar marca o acesso como removido.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/invites/data/repositories/invites_repository.dart';
import 'package:carehub_plus/features/invites/domain/entities/invite_channel.dart';
import 'package:carehub_plus/features/invites/domain/entities/invite_share_entity.dart';
import 'package:carehub_plus/features/network/data/models/network_member_model.dart';
import 'package:carehub_plus/features/network/data/repositories/network_repository.dart';
import 'package:carehub_plus/features/network/presentation/bloc/network_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkRepository extends Mock implements NetworkRepository {}

class MockInvitesRepository extends Mock implements InvitesRepository {}

class FakeMember extends Fake implements NetworkMemberModel {}

void main() {
  late MockNetworkRepository network;
  late MockInvitesRepository invites;

  final invite = InviteShareEntity(
    code: 'ABC234',
    expiresAt: DateTime(2026, 10, 8),
    channel: InviteChannel.app,
    shareText: 'Olá!',
  );

  setUpAll(() {
    registerFallbackValue(FakeMember());
    registerFallbackValue(InviteChannel.app);
  });

  setUp(() {
    network = MockNetworkRepository();
    invites = MockInvitesRepository();
    when(() => network.addMember(any())).thenAnswer(
      (call) async => call.positionalArguments.first as NetworkMemberModel,
    );
  });

  NetworkBloc build() => NetworkBloc(
    repository: network,
    invitesRepository: invites,
    careRecipientId: 'r1',
  );

  const addEvent = NetworkAddMemberEvent(
    name: 'Bia',
    phone: '11988887777',
    role: NetworkRole.family,
    accessDurationHours: 24,
    alertChannels: [AlertChannel.app],
    inviteChannel: InviteChannel.app,
  );

  blocTest<NetworkBloc, NetworkState>(
    'salva o membro com prazo e canal e depois publica o convite',
    build: () {
      when(
        () => invites.createInvite(
          memberId: any(named: 'memberId'),
          channel: InviteChannel.app,
        ),
      ).thenAnswer((_) async => invite);
      return build();
    },
    act: (bloc) => bloc.add(addEvent),
    verify: (bloc) {
      final saved =
          verify(() => network.addMember(captureAny())).captured.single
              as NetworkMemberModel;
      expect(saved.accessDurationHours, 24);
      expect(saved.alertChannels, [AlertChannel.app]);
      expect(bloc.state.addSuccess, isTrue);
      expect(bloc.state.lastInvite, invite);
      expect(bloc.state.members.single.inviteStatus, MemberInviteStatus.pending);
    },
  );

  blocTest<NetworkBloc, NetworkState>(
    'falha no convite não desfaz o membro e vira aviso',
    build: () {
      when(
        () => invites.createInvite(
          memberId: any(named: 'memberId'),
          channel: any(named: 'channel'),
        ),
      ).thenThrow(const AppException('Você atingiu o limite de convites de hoje.'));
      return build();
    },
    act: (bloc) => bloc.add(addEvent),
    verify: (bloc) {
      expect(bloc.state.members, hasLength(1));
      expect(bloc.state.lastInvite, isNull);
      expect(bloc.state.inviteError, 'Você atingiu o limite de convites de hoje.');
    },
  );

  blocTest<NetworkBloc, NetworkState>(
    'sem canal de convite, não chama o backend',
    build: build,
    act: (bloc) => bloc.add(
      const NetworkAddMemberEvent(
        name: 'Bia',
        phone: '11988887777',
        role: NetworkRole.family,
      ),
    ),
    verify: (_) => verifyNever(
      () => invites.createInvite(
        memberId: any(named: 'memberId'),
        channel: any(named: 'channel'),
      ),
    ),
  );

  blocTest<NetworkBloc, NetworkState>(
    'revogar marca o acesso como removido',
    build: () {
      when(() => invites.revokeAccess('m1')).thenAnswer((_) async {});
      return build();
    },
    seed: () => const NetworkState(
      members: [
        NetworkMemberModel(
          id: 'm1',
          name: 'Bia',
          phone: '11988887777',
          role: NetworkRole.family,
          inviteStatus: MemberInviteStatus.active,
        ),
      ],
    ),
    act: (bloc) => bloc.add(const NetworkRevokeAccessEvent(memberId: 'm1')),
    verify: (bloc) {
      expect(bloc.state.members.single.inviteStatus, MemberInviteStatus.revoked);
      expect(bloc.state.isChangingAccess, isFalse);
    },
  );
}
