/*
 * CareHub Plus — Testes / Repositório de convites
 *
 * Confere o que é enviado para cada função e a leitura das respostas,
 * incluindo resposta incompleta e erro do backend.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/invites/data/repositories/invites_repository.dart';
import 'package:carehub_plus/features/invites/domain/entities/invite_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_callable_client.dart';

void main() {
  test('createInvite envia membro e canal e lê o convite', () async {
    final client = FakeCallableClient(
      responses: {
        'createInvite': {
          'code': '7F3K9Q',
          'expiresAt': '2026-10-08T15:00:00.000Z',
          'channel': 'whatsapp',
          'shareText': 'Olá!',
          'shareLink': 'https://wa.me/5511988887777?text=Ol%C3%A1',
        },
      },
    );
    final invite = await InvitesRepository(
      client: client,
    ).createInvite(memberId: 'm1', channel: InviteChannel.whatsapp);

    expect(client.calls.single.name, 'createInvite');
    expect(client.calls.single.data, {'memberId': 'm1', 'channel': 'whatsapp'});
    expect(invite.code, '7F3K9Q');
    expect(invite.channel, InviteChannel.whatsapp);
    expect(invite.shareLink, startsWith('https://wa.me/'));
    expect(invite.expiresAt.isUtc, isFalse);
  });

  test('sem link válido, shareLink fica nulo', () async {
    final client = FakeCallableClient(
      responses: {
        'createInvite': {
          'code': 'ABCDEF',
          'expiresAt': '2026-10-08T15:00:00.000Z',
          'channel': 'app',
          'shareText': 'Olá!',
          'shareLink': null,
        },
      },
    );
    final invite = await InvitesRepository(
      client: client,
    ).createInvite(memberId: 'm1', channel: InviteChannel.app);
    expect(invite.shareLink, isNull);
  });

  test('redeemCode devolve o assistido liberado', () async {
    final client = FakeCallableClient(
      responses: {
        'redeemInviteCode': {
          'careRecipientId': 'r1',
          'careRecipientName': 'Lúcia Maria',
        },
      },
    );
    final redeemed = await InvitesRepository(
      client: client,
    ).redeemCode('7F3K9Q');
    expect(client.calls.single.data, {'code': '7F3K9Q'});
    expect(redeemed.careRecipientId, 'r1');
    expect(redeemed.firstName, 'Lúcia');
  });

  test('claimPendingInvites lê a lista e ignora itens inválidos', () async {
    final client = FakeCallableClient(
      responses: {
        'claimPendingInvites': {
          'claimed': [
            {'careRecipientId': 'r1', 'careRecipientName': 'Lúcia'},
            'lixo',
          ],
        },
      },
    );
    final claimed = await InvitesRepository(
      client: client,
    ).claimPendingInvites();
    expect(claimed.map((item) => item.careRecipientId), ['r1']);
  });

  test('resposta incompleta vira AppException clara', () async {
    final client = FakeCallableClient(
      responses: {
        'createSelfLinkCode': {'code': 'ABCDEF'},
      },
    );
    expect(
      InvitesRepository(client: client).createSelfLinkCode(),
      throwsA(isA<AppException>()),
    );
  });

  test('erro do backend chega com a mensagem original', () async {
    final client = FakeCallableClient(
      responses: {
        'revokeAccess': const AppException(
          'Acesso não encontrado.',
          code: 'not-found',
        ),
      },
    );
    expect(
      InvitesRepository(client: client).revokeAccess('m1'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Acesso não encontrado.',
        ),
      ),
    );
  });
}
