/*
 * CareHub Plus — Functions / Trigger de chat criado
 *
 * Quando o app cria uma sala de chat com responsável (responsibleMemberId),
 * avisa esse membro dentro do CareHub (sino + push). A sala não grava o
 * dono; ele é descoberto pelo perfil cuidado, e o aviso só sai se o membro
 * pertence ao mesmo cuidador — ninguém usa o backend para notificar a rede
 * de outra pessoa.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

import { REGION } from "../config";
import { AppNotifier } from "../notifications/appNotifier";
import { CareRepository } from "../repositories/careRepository";
import { MessageLogRepository } from "../repositories/messageLogRepository";
import { firstName, templateParam } from "../shared/text";

export const onChatRoomCreated = onDocumentCreated(
  { document: "chat_rooms/{roomId}", region: REGION },
  async (event) => {
    const room = event.data?.data();
    const roomId = event.params.roomId;
    const memberId = room?.responsibleMemberId as string | undefined;
    const careRecipientId = (room?.careRecipientId as string | undefined) ?? null;

    if (!room || !memberId || !careRecipientId) return;

    const care = new CareRepository();
    const [member, caregiverId] = await Promise.all([
      care.getMember(memberId),
      care.getCareRecipientOwnerId(careRecipientId),
    ]);

    if (!member || !caregiverId || member.caregiverId !== caregiverId) {
      logger.warn("Chat ignorado: membro não pertence ao cuidador.", { roomId });
      return;
    }

    // Triggers podem rodar mais de uma vez para o mesmo evento.
    if (!(await new MessageLogRepository().acquireDispatchLock(`chat_room_${roomId}`))) return;

    const caregiverName = await care.getCaregiverName(caregiverId);
    const recipientName =
      (room.careRecipientName as string | undefined) ??
      (await care.getCareRecipientName(careRecipientId)) ??
      "seu familiar";

    await new AppNotifier().notifyMember(member, {
      type: "chat",
      title: "Novo chat com você",
      body: `${caregiverName ? firstName(caregiverName) : "Sua rede de apoio"} abriu o assunto "${
        templateParam(room.title as string | undefined)
      }" sobre ${recipientName}.`,
      relatedId: roomId,
      caregiverId,
      careRecipientId,
    });
  },
);
