/*
 * CareHub Plus — Domínio / Código para ligar o WhatsApp da dona
 *
 * Código curto (10 minutos) que a dona envia do próprio WhatsApp para ligar
 * o número à conta. A partir daí, o número é o "login" dela na Cora pelo
 * WhatsApp — a Meta garante de qual número a mensagem saiu.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Código para ativar a Cora no WhatsApp da dona.
class WhatsAppLinkEntity extends Equatable {
  const WhatsAppLinkEntity({
    required this.code,
    required this.expiresAt,
    required this.link,
  });

  final String code;
  final DateTime expiresAt;

  /// Abre a conversa com o CareHub já com `ENTRAR <código>` escrito.
  final String link;

  @override
  List<Object?> get props => [code, expiresAt, link];
}
