/*
 * CareHub Plus — Domínio SOS / Aceite do pedido de ajuda
 *
 * Resposta de um membro da rede de apoio a um pedido de ajuda: quem aceitou.
 * Guarda apenas o id do membro — o nome e a foto vivem na feature `network`,
 * e resolver isso aqui acoplaria as duas camadas. O tempo de chegada não é
 * guardado: o WhatsApp não informa, e um valor inventado induziria a erro.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.1.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Aceite de um pedido de ajuda por um membro da rede de apoio.
class SosAcceptanceEntity extends Equatable {
  const SosAcceptanceEntity({required this.memberId});

  /// Id do membro da rede de apoio que aceitou o chamado.
  final String memberId;

  @override
  List<Object?> get props => [memberId];
}
