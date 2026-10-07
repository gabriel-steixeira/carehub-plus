/*
 * CareHub Plus — Functions / Trigger de tarefa atribuída
 *
 * Quando o app cria uma tarefa com responsável (assignedToMemberId), avisa
 * esse membro da rede de apoio pelo WhatsApp com botões Aceitar/Recusar.
 * Não exige mudança no app: reage ao documento que o TasksRepository já grava.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

import { REGION, whatsappToken } from "../config";
import { CareRepository, wantsAlertBy } from "../repositories/careRepository";
import { AppNotifier } from "../notifications/appNotifier";
import { MessageLogRepository } from "../repositories/messageLogRepository";
import { firstName, formatScheduledTime, templateParam } from "../shared/text";
import { ButtonAction, buildPayload, TASK_ASSIGNED_TEMPLATE } from "../whatsapp/templates";
import { createMessenger } from "../whatsapp/whatsappMessenger";

export const onTaskAssigned = onDocumentCreated(
  { document: "tasks/{taskId}", region: REGION, secrets: [whatsappToken] },
  async (event) => {
    const task = event.data?.data();
    const taskId = event.params.taskId;
    const memberId = task?.assignedToMemberId as string | undefined;
    const caregiverId = task?.caregiverId as string | undefined;

    if (!task || !memberId || !caregiverId || task.isCompleted === true) return;

    const care = new CareRepository();
    const member = await care.getMember(memberId);

    // As regras de "tasks" ainda aceitam qualquer usuário logado. Só envia se
    // o membro pertence ao mesmo cuidador da tarefa, para ninguém usar o
    // backend para mandar mensagem para a rede de outra pessoa.
    if (!member || member.caregiverId !== caregiverId) {
      logger.warn("Tarefa ignorada: membro não pertence ao cuidador.", { taskId });
      return;
    }

    const log = new MessageLogRepository();
    if (!(await log.acquireDispatchLock(`task_${taskId}`))) return;

    const [caregiverName, recipientName] = await Promise.all([
      care.getCaregiverName(caregiverId),
      care.getCareRecipientName(task.careRecipientId as string | undefined),
    ]);

    // Aviso no app (sino + push), se a dona escolheu esse canal para o membro.
    if (wantsAlertBy(member, "app")) {
      await new AppNotifier().notifyMember(member, {
        type: "task",
        title: "Nova tarefa para você",
        body: `${caregiverName ? firstName(caregiverName) : "Sua rede de apoio"} incluiu você na tarefa "${
          templateParam(task.title as string | undefined)
        }" de ${recipientName ?? "seu familiar"}, em ${formatScheduledTime(
          task.scheduledTime as string | undefined,
        )}.`,
        relatedId: taskId,
        caregiverId,
        careRecipientId: (task.careRecipientId as string | undefined) ?? null,
      });
    }

    if (!wantsAlertBy(member, "whatsapp")) return;

    await createMessenger().sendTemplate(
      member,
      {
        memberId: member.id,
        memberName: member.name,
        caregiverId,
        careRecipientId: (task.careRecipientId as string | undefined) ?? null,
        relatedType: "task",
        relatedId: taskId,
      },
      {
        name: TASK_ASSIGNED_TEMPLATE,
        bodyParams: [
          firstName(member.name),
          caregiverName ? firstName(caregiverName) : "Sua rede de apoio",
          templateParam(recipientName ?? "seu familiar"),
          templateParam(task.title as string | undefined),
          formatScheduledTime(task.scheduledTime as string | undefined),
        ],
        quickReplyPayloads: [
          buildPayload({ action: ButtonAction.taskAccept, targetId: taskId, memberId }),
          buildPayload({ action: ButtonAction.taskDecline, targetId: taskId, memberId }),
        ],
      },
    );
  },
);
