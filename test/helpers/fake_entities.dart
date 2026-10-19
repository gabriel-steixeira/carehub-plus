/*
 * CareHub Plus — Test Helpers / Fakes compartilhados
 *
 * Fábricas de entidades/dados usados pelos testes, para evitar duplicar o
 * mesmo objeto em vários arquivos. Nenhum acesso real ao Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/features/sos/domain/entities/sos_alert_detail_entity.dart';
import 'package:carehub_plus/features/sos/domain/entities/sos_alert_snapshot_entity.dart';

/// Detalhe de alerta de SOS pronto para os testes.
SosAlertDetailEntity fakeSosAlertDetail({
  String alertId = 'sos_1',
  SosAlertStatus status = SosAlertStatus.dispatched,
  String? acceptedByMemberId,
}) {
  return SosAlertDetailEntity(
    alertId: alertId,
    requestedByUid: 'uid_requester',
    requestedByName: 'Maria',
    careRecipientId: 'care_1',
    taskId: 'task_1',
    taskTitle: 'Dar o remédio das 14h',
    status: status,
    createdAt: DateTime(2026, 10, 18, 14),
    acceptedByMemberId: acceptedByMemberId,
    notifiedMemberIds: const ['member_1'],
  );
}
