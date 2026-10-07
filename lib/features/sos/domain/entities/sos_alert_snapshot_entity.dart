/*
 * CareHub Plus — Domínio SOS / Situação do alerta em andamento
 *
 * Retrato do documento `sos_alerts/{id}` depois que o aviso sai pelo WhatsApp:
 * em que etapa o alerta está, quem aceitou, quem recusou e quantos avisos o
 * backend conseguiu entregar à Meta. É a resposta real da rede de apoio — o
 * app só lê; quem grava as respostas é o webhook do WhatsApp.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Etapa do alerta gravada no Firestore.
enum SosAlertStatus {
  /// Criado, ainda dentro da janela de cancelamento.
  pending,

  /// Aviso liberado: o backend envia o WhatsApp para a rede.
  dispatched,

  /// Alguém respondeu "Estou indo".
  accepted,

  /// Cancelado pela cuidadora.
  cancelled,

  /// Valor que o app não conhece — tratado como "ainda aguardando".
  unknown,
}

/// Resposta de um membro da rede ao pedido de ajuda.
enum SosMemberResponse { accepted, declined }

/// Situação atual de um alerta de SOS.
class SosAlertSnapshotEntity extends Equatable {
  const SosAlertSnapshotEntity({
    required this.status,
    this.acceptedByMemberId,
    this.responses = const {},
    this.whatsappSent,
    this.whatsappFailed,
  });

  final SosAlertStatus status;

  /// Primeiro membro que aceitou. Só existe quando [status] é `accepted`.
  final String? acceptedByMemberId;

  /// Resposta de cada membro que já respondeu, indexada pelo id do membro.
  final Map<String, SosMemberResponse> responses;

  /// Avisos aceitos pela Meta. `null` enquanto o backend não terminou o envio.
  final int? whatsappSent;

  /// Avisos recusados pela Meta ou não enviados (telefone inválido, cota).
  final int? whatsappFailed;

  /// O alerta foi aceito por alguém da rede.
  bool get isAccepted =>
      status == SosAlertStatus.accepted && acceptedByMemberId != null;

  /// O backend terminou e nenhum aviso foi entregue à Meta.
  bool get deliveryFailedForAll =>
      whatsappSent == 0 && (whatsappFailed ?? 0) > 0;

  /// O backend terminou e parte dos avisos não foi entregue.
  bool get deliveryFailedForSome =>
      (whatsappSent ?? 0) > 0 && (whatsappFailed ?? 0) > 0;

  /// O membro respondeu "Não posso".
  bool hasDeclined(String memberId) =>
      responses[memberId] == SosMemberResponse.declined;

  @override
  List<Object?> get props => [
    status,
    acceptedByMemberId,
    responses,
    whatsappSent,
    whatsappFailed,
  ];
}
