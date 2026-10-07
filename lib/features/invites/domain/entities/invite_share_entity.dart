/*
 * CareHub Plus — Domínio / Convite pronto para compartilhar
 *
 * O que o backend devolve ao criar um convite: o código, até quando ele vale
 * e a mensagem pronta. O envio sai do aparelho da própria dona (WhatsApp ou
 * compartilhar), então não consome a cota de mensagens do CareHub.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'invite_channel.dart';

/// Convite criado e pronto para enviar.
class InviteShareEntity extends Equatable {
  const InviteShareEntity({
    required this.code,
    required this.expiresAt,
    required this.channel,
    required this.shareText,
    this.shareLink,
  });

  /// Código de 6 caracteres (só aparece aqui; o banco guarda o hash).
  final String code;
  final DateTime expiresAt;
  final InviteChannel channel;

  /// Mensagem pronta para a dona enviar.
  final String shareText;

  /// Abre o WhatsApp da dona já na conversa com o membro. `null` quando o
  /// telefone do membro não é válido para WhatsApp.
  final String? shareLink;

  @override
  List<Object?> get props => [code, expiresAt, channel, shareText, shareLink];
}
