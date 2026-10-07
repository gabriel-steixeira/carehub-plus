/*
 * CareHub Plus — Dados / Modelos das respostas de convite
 *
 * Leitura manual (fromJson) das respostas das funções de convite. Valores
 * ausentes ou de tipo errado viram erro claro, em vez de quebrar a tela
 * com uma conversão inesperada.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/invite_channel.dart';
import '../../domain/entities/invite_share_entity.dart';
import '../../domain/entities/redeemed_invite_entity.dart';
import '../../domain/entities/whatsapp_link_entity.dart';

const _invalidResponse = AppException(
  'Resposta inesperada do servidor. Tente novamente.',
);

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw _invalidResponse;
}

DateTime _requireDate(Map<String, dynamic> json, String key) {
  final parsed = DateTime.tryParse(_requireString(json, key));
  if (parsed == null) throw _invalidResponse;
  return parsed.toLocal();
}

/// Resposta de `createInvite`.
abstract final class InviteShareModel {
  static InviteShareEntity fromJson(Map<String, dynamic> json) {
    final link = json['shareLink'];
    return InviteShareEntity(
      code: _requireString(json, 'code'),
      expiresAt: _requireDate(json, 'expiresAt'),
      channel: InviteChannel.fromValue(json['channel'] as String?),
      shareText: _requireString(json, 'shareText'),
      shareLink: link is String && link.isNotEmpty ? link : null,
    );
  }
}

/// Item de `redeemInviteCode` e de `claimPendingInvites`.
abstract final class RedeemedInviteModel {
  static RedeemedInviteEntity fromJson(Map<String, dynamic> json) {
    final name = json['careRecipientName'];
    return RedeemedInviteEntity(
      careRecipientId: _requireString(json, 'careRecipientId'),
      careRecipientName: name is String ? name : '',
    );
  }
}

/// Resposta de `createSelfLinkCode`.
abstract final class WhatsAppLinkModel {
  static WhatsAppLinkEntity fromJson(Map<String, dynamic> json) {
    return WhatsAppLinkEntity(
      code: _requireString(json, 'code'),
      expiresAt: _requireDate(json, 'expiresAt'),
      link: _requireString(json, 'link'),
    );
  }
}
