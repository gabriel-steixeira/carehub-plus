/*
 * CareHub Plus — Domínio SOS / Aceite do pedido de ajuda
 *
 * Resposta de um membro da rede de apoio a um pedido de ajuda: quem aceitou e
 * em quanto tempo deve chegar. Guarda apenas o id do membro — o nome e a foto
 * vivem na feature `network`, e resolver isso aqui acoplaria as duas camadas.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Aceite de um pedido de ajuda por um membro da rede de apoio.
class SosAcceptanceEntity extends Equatable {
  const SosAcceptanceEntity({
    required this.memberId,
    required this.etaMinutes,
  });

  /// Id do membro da rede de apoio que aceitou o chamado.
  final String memberId;

  /// Tempo estimado de chegada, em minutos.
  final int etaMinutes;

  @override
  List<Object?> get props => [memberId, etaMinutes];
}
