/*
 * CareHub Plus — Domínio SOS / Detalhe de um pedido de ajuda
 *
 * Retrato descritivo do documento `sos_alerts/{id}` usado pela tela aberta ao
 * tocar na notificação de SOS: quem pediu, qual perfil cuidado, qual tarefa e
 * em que etapa o pedido está. Diferente do `SosAlertSnapshotEntity` (que só
 * acompanha status e respostas em tempo real), esta entidade carrega os campos
 * que a tela de detalhe precisa mostrar. Dart puro — sem dependência do
 * Firebase; quem lê o documento é o repositório.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'sos_alert_snapshot_entity.dart';

/// Detalhe de um pedido de ajuda, para a tela aberta pela notificação.
class SosAlertDetailEntity extends Equatable {
  const SosAlertDetailEntity({
    required this.alertId,
    required this.requestedByUid,
    this.requestedByName,
    required this.careRecipientId,
    this.taskId,
    this.taskTitle,
    required this.status,
    required this.createdAt,
    this.acceptedByMemberId,
    this.notifiedMemberIds = const [],
  });

  /// Id do documento em `sos_alerts`.
  final String alertId;

  /// Quem disparou o pedido (uid do Firebase).
  final String requestedByUid;

  /// Nome de quem pediu, quando gravado (perfil compartilhado). Pode ser nulo.
  final String? requestedByName;

  /// Perfil cuidado a que o pedido se refere.
  final String careRecipientId;

  /// Tarefa que motivou o pedido, quando houver.
  final String? taskId;

  /// Título da tarefa que motivou o pedido, quando houver.
  final String? taskTitle;

  /// Etapa atual do alerta (reusa o enum do snapshot em tempo real).
  final SosAlertStatus status;

  /// Quando o pedido foi criado.
  final DateTime createdAt;

  /// Primeiro membro que aceitou. Só existe quando [status] é `accepted`.
  final String? acceptedByMemberId;

  /// Membros da rede de apoio avisados neste pedido.
  final List<String> notifiedMemberIds;

  @override
  List<Object?> get props => [
    alertId,
    requestedByUid,
    requestedByName,
    careRecipientId,
    taskId,
    taskTitle,
    status,
    createdAt,
    acceptedByMemberId,
    notifiedMemberIds,
  ];
}
