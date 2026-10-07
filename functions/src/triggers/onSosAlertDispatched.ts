/*
 * CareHub Plus — Functions / Trigger de SOS
 *
 * Avisa pelo WhatsApp os membros escolhidos no SOS quando o alerta em
 * sos_alerts/{alertId} passa para o status "dispatched". O app grava
 * "pending" ao abrir o pedido e "dispatched" quando a janela de
 * cancelamento termina; assim, um SOS cancelado não gera mensagem.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

import { REGION, whatsappToken } from "../config";
import { CareRepository, wantsAlertBy } from "../repositories/careRepository";
import { MessageLogRepository } from "../repositories/messageLogRepository";
import { AppNotifier } from "../notifications/appNotifier";
import { firstName, templateParam } from "../shared/text";
import { ButtonAction, buildPayload, SOS_ALERT_TEMPLATE } from "../whatsapp/templates";
import { createMessenger } from "../whatsapp/whatsappMessenger";

/** Limite de pessoas avisadas por SOS (controle de custo). */
const MAX_MEMBERS_PER_ALERT = 10;

export const onSosAlertDispatched = onDocumentWritten(
  { document: "sos_alerts/{alertId}", region: REGION, secrets: [whatsappToken] },
  async (event) => {
    const before = event.data?.before.data();
    const alert = event.data?.after.data();
    const alertId = event.params.alertId;

    const becameDispatched = alert?.status === "dispatched" && before?.status !== "dispatched";
    if (!alert || !becameDispatched) return;

    const caregiverId = alert.caregiverId as string | undefined;
    const memberIds = ((alert.notifiedMemberIds as string[] | undefined) ?? []).slice(
      0,
      MAX_MEMBERS_PER_ALERT,
    );
    if (!caregiverId || memberIds.length === 0) return;

    const log = new MessageLogRepository();
    if (!(await log.acquireDispatchLock(`sos_${alertId}`))) return;

    const care = new CareRepository();
    const careRecipientId = (alert.careRecipientId as string | undefined) ?? null;
    const [members, caregiverName, recipientName] = await Promise.all([
      care.getMembers(memberIds),
      care.getCaregiverName(caregiverId),
      care.getCareRecipientName(careRecipientId),
    ]);

    const messenger = createMessenger();
    const notifier = new AppNotifier();
    // Pedido aberto por alguém da rede (app ou WhatsApp): o nome é de quem pediu.
    const requesterName = (alert.requestedByName as string | undefined) ?? caregiverName;

    // Aberto pelo app por uma pessoa convidada: a dona fica sabendo. (Pelo
    // WhatsApp, a própria conversa da Cora já avisa a dona.)
    const requestedByUid = alert.requestedByUid as string | undefined;
    if (requestedByUid && requestedByUid !== caregiverId && alert.channel !== "whatsapp") {
      await new AppNotifier().notifyUid(caregiverId, {
        type: "sos",
        title: "SOS aberto por alguém da rede",
        body: `${requesterName ? firstName(requesterName) : "Alguém da rede"} pediu ajuda para ${
          recipientName ?? "seu familiar"
        }: ${templateParam(alert.taskTitle as string | undefined)}.`,
        relatedId: alertId,
        caregiverId,
        careRecipientId,
      });
    }
    const askerName = requesterName ? firstName(requesterName) : "Sua rede de apoio";
    let sent = 0;
    let failed = 0;

    for (const member of members) {
      if (member.caregiverId !== caregiverId) {
        logger.warn("SOS: membro de outro cuidador ignorado.", { alertId, memberId: member.id });
        failed++;
        continue;
      }

      // Aviso no app (sino + push), se a dona escolheu esse canal para o membro.
      if (wantsAlertBy(member, "app")) {
        await notifier.notifyMember(member, {
          type: "sos",
          title: "Pedido de ajuda (SOS)",
          body: `${askerName} precisa de ajuda com ${recipientName ?? "seu familiar"}: ${
            templateParam(alert.taskTitle as string | undefined)
          }.`,
          relatedId: alertId,
          caregiverId,
          careRecipientId,
        });
      }

      // Só app: não entra no resumo do WhatsApp (não é falha de envio).
      if (!wantsAlertBy(member, "whatsapp")) continue;

      const result = await messenger.sendTemplate(
        member,
        {
          memberId: member.id,
          memberName: member.name,
          caregiverId,
          careRecipientId,
          relatedType: "sos",
          relatedId: alertId,
        },
        {
          name: SOS_ALERT_TEMPLATE,
          bodyParams: [
            templateParam(recipientName ?? "seu familiar"),
            requesterName ? firstName(requesterName) : "A pessoa cuidadora",
            templateParam(alert.taskTitle as string | undefined),
          ],
          quickReplyPayloads: [
            buildPayload({ action: ButtonAction.sosAccept, targetId: alertId, memberId: member.id }),
            buildPayload({ action: ButtonAction.sosDecline, targetId: alertId, memberId: member.id }),
          ],
        },
        // Cota própria do SOS: conversar com a Cora nunca bloqueia este envio.
        "sos",
      );
      if (result === "sent") {
        sent++;
      } else {
        failed++;
      }
    }

    await care.saveSosDispatchSummary(alertId, sent, failed);
  },
);
