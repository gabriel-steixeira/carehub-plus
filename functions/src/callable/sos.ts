/*
 * CareHub Plus — Functions / Callable de aceite do SOS
 *
 * Função chamada pelo app (FirebaseFunctions.httpsCallable) para o membro
 * acionado aceitar um pedido de SOS ("Estou a caminho"). Exige login; quem é
 * a pessoa vem do token do Firebase Auth, nunca do corpo da requisição. O
 * aceite reusa a transação já testada `CareRepository.registerSosResponse`
 * (o app não pode escrever no alerta de outra pessoa) e, no primeiro aceite,
 * avisa de volta quem pediu ajuda pela notificação do app (tipo `sos`).
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import { GrantRepository } from "../access/grantRepository";
import { REGION } from "../config";
import { AppNotifier } from "../notifications/appNotifier";
import { CareRepository } from "../repositories/careRepository";
import { db } from "../shared/firestore";

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
    const grants = new GrantRepository();
    let memberId: string | null = null;
    for (const candidate of notified) {
      const grant = await grants.getByMember(candidate);
      if (grant?.principalUid === uid) {
        memberId = candidate;
        break;
      }
    }
    if (!memberId) {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    const care = new CareRepository();
    const result = await care.registerSosResponse(alertId, memberId, true);

    if (result === "accepted_first" || result === "already_accepted") {
      const requesterUid =
        (snap.get("requestedByUid") as string) ?? (snap.get("caregiverId") as string);
      const caregiverId = snap.get("caregiverId") as string;
      const careRecipientId = (snap.get("careRecipientId") as string | null) ?? null;
      const name = (await care.getMember(memberId))?.name || "Um contato da rede";
      await new AppNotifier().notifyUid(requesterUid, {
        type: "sos",
        title: "Alguém está a caminho",
        body: `${name} aceitou seu pedido de ajuda.`,
        relatedId: alertId,
        caregiverId,
        careRecipientId,
      });
    }

    if (result === "not_allowed") {
      throw new HttpsError("permission-denied", "Você não foi acionada neste pedido.");
    }

    return { status: result };
  }),
);
