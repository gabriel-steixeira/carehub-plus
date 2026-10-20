/*
 * CareHub Plus — Functions / Callables do SOS
 *
 * Funções chamadas pelo app (FirebaseFunctions.httpsCallable) para o fluxo do
 * SOS visto por quem recebe o pedido: abrir o detalhe (`getSosAlertDetail`) e
 * aceitar ("Estou a caminho", `acceptSosAlert`). Exigem login; quem é a pessoa
 * vem do token do Firebase Auth, nunca do corpo da requisição. As regras do
 * Firestore não deixam o membro acionado ler nem escrever no alerta de outra
 * pessoa, então estas callables fazem o acesso com o Admin SDK depois de
 * provar, pela concessão de acesso (`access_grants.principalUid`), que quem
 * chama é mesmo um membro acionado. O aceite reusa a transação já testada
 * `CareRepository.registerSosResponse` e, no primeiro aceite, avisa de volta
 * quem pediu ajuda pela notificação do app (tipo `sos`).
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { GrantRepository } from "../access/grantRepository";
import { REGION } from "../config";
import { AppNotifier } from "../notifications/appNotifier";
import { CareRepository } from "../repositories/careRepository";
import { ConversationContext } from "../repositories/messageLogRepository";
import { db } from "../shared/firestore";
import { createMessenger } from "../whatsapp/whatsappMessenger";

function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Entre na sua conta para continuar.");
  return uid;
}

function requireString(value: unknown, field: string, maxLength = 200): string {
  if (typeof value !== "string" || !value.trim() || value.length > maxLength) {
    throw new HttpsError("invalid-argument", `Campo "${field}" inválido.`);
  }
  return value.trim();
}

/** Converte erros conhecidos e esconde os desconhecidos. */
async function run<T>(work: () => Promise<T>): Promise<T> {
  try {
    return await work();
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Não foi possível concluir agora. Tente novamente.");
  }
}

const options = { region: REGION, maxInstances: 5 };

/**
 * Descobre qual membro acionado corresponde ao `uid` autenticado, cruzando o
 * token com a conta ligada a cada membro em `notifiedMemberIds`
 * (`access_grants.principalUid`). Retorna `null` quando quem chama não é um
 * membro acionado do pedido.
 */
async function resolveNotifiedMemberId(
  uid: string,
  notifiedMemberIds: string[],
): Promise<string | null> {
  const grants = new GrantRepository();
  for (const candidate of notifiedMemberIds) {
    const grant = await grants.getByMember(candidate);
    if (grant?.principalUid === uid) return candidate;
  }
  return null;
}

/**
 * Avisa quem pediu ajuda sobre a resposta de um membro, pelo mesmo canal de
 * onde o pedido saiu. Pedido feito pelo WhatsApp (`channel === 'whatsapp'` e
 * `requestedBy` no formato `wa:<telefone>`) responde pelo WhatsApp, dentro da
 * janela de 24h já aberta; pedido feito pelo app notifica a conta pelo app.
 * O envio pelo WhatsApp é tolerante a falha: registra e segue, nunca lança.
 */
async function notifyRequesterByChannel(
  snap: FirebaseFirestore.DocumentSnapshot,
  memberName: string,
  kind: "accept" | "decline",
): Promise<void> {
  const channel = snap.get("channel") as string | undefined;
  const requestedBy = snap.get("requestedBy") as string | undefined;
  const requestedByUid = snap.get("requestedByUid") as string | undefined;
  const caregiverId = snap.get("caregiverId") as string;
  const careRecipientId = (snap.get("careRecipientId") as string | null) ?? null;
  const alertId = snap.id;

  const appTitle = kind === "accept" ? "Alguém está a caminho" : "Resposta ao seu pedido";
  const appBody =
    kind === "accept"
      ? `${memberName} aceitou seu pedido de ajuda.`
      : `${memberName} não poderá ajudar desta vez.`;
  const waBody =
    kind === "accept"
      ? `${memberName} está a caminho para ajudar.`
      : `${memberName} não poderá ajudar desta vez.`;

  if (channel === "whatsapp" && typeof requestedBy === "string" && requestedBy.startsWith("wa:")) {
    const toKey = requestedBy.slice(3);
    try {
      const context: ConversationContext = {
        memberId: "",
        memberName: "",
        caregiverId: caregiverId ?? "",
        careRecipientId,
        relatedType: "sos",
        relatedId: alertId,
      };
      const messenger = createMessenger();
      const result = await messenger.replyInWindow(toKey, context, waBody, {
        bucket: "sos",
        quotaKey: `wa:${toKey}`,
      });
      if (result !== "sent") {
        logger.warn("WhatsApp ao emissor do SOS não enviado.", { alertId, result });
      }
    } catch (error) {
      logger.error("Falha ao avisar o emissor do SOS pelo WhatsApp.", {
        alertId,
        reason: error instanceof Error ? error.message : String(error),
      });
      return;
    }
    return;
  }

  const uid = requestedByUid ?? caregiverId;
  await new AppNotifier().notifyUid(uid, {
    type: "sos",
    title: appTitle,
    body: appBody,
    relatedId: alertId,
    caregiverId,
    careRecipientId,
  });
}

/**
 * Devolve os dados do pedido de SOS para a tela de detalhe de quem recebeu o
 * aviso. As regras do Firestore não deixam o membro acionado ler o alerta
 * direto, então a leitura é mediada aqui: libera para a dona (`caregiverId`),
 * para quem abriu (`requestedByUid`) e para qualquer membro acionado.
 */
export const getSosAlertDetail = onCall(options, (request) =>
  run(async () => {
    const uid = requireUid(request);
    const alertId = requireString(request.data?.alertId, "alertId");

    const snap = await db.collection("sos_alerts").doc(alertId).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Pedido de ajuda não encontrado.");
    }

    const caregiverId = snap.get("caregiverId") as string;
    const requestedByUid = (snap.get("requestedByUid") as string | null) ?? null;
    const notified = (snap.get("notifiedMemberIds") as string[] | undefined) ?? [];

    const isParty = uid === caregiverId || uid === requestedByUid;
    if (!isParty && !(await resolveNotifiedMemberId(uid, notified))) {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    return {
      alertId,
      requestedByUid: requestedByUid ?? caregiverId,
      requestedByName: (snap.get("requestedByName") as string | null) ?? null,
      careRecipientId: (snap.get("careRecipientId") as string | null) ?? null,
      taskId: (snap.get("taskId") as string | null) ?? null,
      taskTitle: (snap.get("taskTitle") as string | null) ?? null,
      status: (snap.get("status") as string | null) ?? null,
      createdAt: (snap.get("createdAt") as string | null) ?? null,
      acceptedByMemberId: (snap.get("acceptedByMemberId") as string | null) ?? null,
      notifiedMemberIds: notified,
    };
  }),
);

/**
 * Aceita um pedido de SOS em nome do membro autenticado.
 *
 * Resolve o `memberId` do chamador cruzando o `uid` do token com a conta
 * ligada a cada membro acionado (`access_grants.principalUid`); só quem está
 * em `notifiedMemberIds` pode aceitar. No primeiro ("Estou a caminho") o
 * alerta vira `accepted` e quem pediu ajuda recebe uma notificação de volta.
 */
export const acceptSosAlert = onCall(options, (request) =>
  run(async () => {
    const uid = requireUid(request);
    const alertId = requireString(request.data?.alertId, "alertId");

    const snap = await db.collection("sos_alerts").doc(alertId).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Pedido de ajuda não encontrado.");
    }

    const notified = (snap.get("notifiedMemberIds") as string[] | undefined) ?? [];
    const memberId = await resolveNotifiedMemberId(uid, notified);
    if (!memberId) {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    const care = new CareRepository();
    const result = await care.registerSosResponse(alertId, memberId, true);

    if (result === "accepted_first" || result === "already_accepted") {
      const name = (await care.getMember(memberId))?.name || "Um contato da rede";
      await notifyRequesterByChannel(snap, name, "accept");
    }

    if (result === "not_allowed") {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    return { status: result };
  }),
);

/**
 * Recusa um pedido de SOS em nome do membro autenticado ("Não posso ajudar
 * agora"). Espelha `acceptSosAlert`: resolve o `memberId` pela concessão de
 * acesso e reusa a transação `CareRepository.registerSosResponse`, que grava a
 * recusa sem mexer no `status` nem no `acceptedByMemberId`. Em caso de recusa,
 * avisa quem pediu ajuda pelo mesmo canal de onde o pedido saiu.
 */
export const declineSosAlert = onCall(options, (request) =>
  run(async () => {
    const uid = requireUid(request);
    const alertId = requireString(request.data?.alertId, "alertId");

    const snap = await db.collection("sos_alerts").doc(alertId).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Pedido de ajuda não encontrado.");
    }

    const notified = (snap.get("notifiedMemberIds") as string[] | undefined) ?? [];
    const memberId = await resolveNotifiedMemberId(uid, notified);
    if (!memberId) {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    const care = new CareRepository();
    const result = await care.registerSosResponse(alertId, memberId, false);

    if (result === "not_allowed") {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    if (result === "declined") {
      const name = (await care.getMember(memberId))?.name || "Um contato da rede";
      await notifyRequesterByChannel(snap, name, "decline");
    }

    return { status: result };
  }),
);
