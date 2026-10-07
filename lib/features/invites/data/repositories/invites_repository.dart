/*
 * CareHub Plus — Dados / Repositório de convites e acesso compartilhado
 *
 * Porta única do app para as funções de convite do backend. Quem decide se
 * a pessoa pode convidar, aceitar ou revogar é o servidor (com o login do
 * Firebase); este repositório só envia o pedido e lê a resposta.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../../../services/cloud_functions_service.dart';
import '../../domain/entities/invite_channel.dart';
import '../../domain/entities/invite_share_entity.dart';
import '../../domain/entities/redeemed_invite_entity.dart';
import '../../domain/entities/whatsapp_link_entity.dart';
import '../models/invite_models.dart';

/// Convites da rede de apoio e vínculo do WhatsApp.
class InvitesRepository {
  InvitesRepository({CallableClient? client})
    : _client = client ?? CloudFunctionsService();

  final CallableClient _client;

  /// A dona cria (ou reenvia) o convite de um membro da rede.
  Future<InviteShareEntity> createInvite({
    required String memberId,
    required InviteChannel channel,
  }) async {
    final data = await _client.call('createInvite', {
      'memberId': memberId,
      'channel': channel.value,
    });
    return InviteShareModel.fromJson(data);
  }

  /// Cancela o convite pendente de um membro.
  Future<void> cancelInvite(String memberId) async {
    await _client.call('cancelInvite', {'memberId': memberId});
  }

  /// Remove o acesso do membro imediatamente (app e WhatsApp).
  Future<void> revokeAccess(String memberId) async {
    await _client.call('revokeAccess', {'memberId': memberId});
  }

  /// Tela "Tenho um convite": usa o código digitado.
  Future<RedeemedInviteEntity> redeemCode(String code) async {
    final data = await _client.call('redeemInviteCode', {'code': code});
    return RedeemedInviteModel.fromJson(data);
  }

  /// Ao entrar no app: aceita os convites do e-mail verificado da conta.
  Future<List<RedeemedInviteEntity>> claimPendingInvites() async {
    final data = await _client.call('claimPendingInvites');
    final claimed = data['claimed'];
    if (claimed is! List) return const [];
    return claimed
        .whereType<Map<String, dynamic>>()
        .map(RedeemedInviteModel.fromJson)
        .toList();
  }

  /// Código para a dona ligar o próprio WhatsApp à conta.
  Future<WhatsAppLinkEntity> createSelfLinkCode() async {
    final data = await _client.call('createSelfLinkCode');
    return WhatsAppLinkModel.fromJson(data);
  }
}
