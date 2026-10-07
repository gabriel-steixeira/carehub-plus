/*
 * CareHub Plus — Functions / Callables de convite e acesso
 *
 * Funções chamadas pelo app (FirebaseFunctions.httpsCallable). Todas exigem
 * login; quem é a pessoa vem do token do Firebase Auth, nunca do corpo da
 * requisição. Erros saem como HttpsError com mensagem pronta para exibir.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import { InviteError, InviteService } from "../access/inviteService";
import { Channel } from "../access/types";
import {
  codeAttemptsDailyLimit,
  inviteDailyLimit,
  REGION,
  whatsappDisplayNumber,
} from "../config";

function service(): InviteService {
  return new InviteService(whatsappDisplayNumber.value(), {
    invitesPerDay: inviteDailyLimit.value(),
    codeAttemptsPerDay: codeAttemptsDailyLimit.value(),
  });
}

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
    if (error instanceof InviteError) throw new HttpsError(error.code, error.message);
    throw new HttpsError("internal", "Não foi possível concluir agora. Tente novamente.");
  }
}

const options = { region: REGION, maxInstances: 5 };

export const createInvite = onCall(options, (request) =>
  run(() => {
    const uid = requireUid(request);
    const memberId = requireString(request.data?.memberId, "memberId");
    const channel = request.data?.channel;
    if (channel !== "app" && channel !== "whatsapp") {
      throw new HttpsError("invalid-argument", 'Campo "channel" inválido.');
    }
    return service().createInvite(uid, memberId, channel as Channel);
  }),
);

export const cancelInvite = onCall(options, (request) =>
  run(async () => {
    await service().cancelInvite(requireUid(request), requireString(request.data?.memberId, "memberId"));
    return { ok: true };
  }),
);

export const revokeAccess = onCall(options, (request) =>
  run(async () => {
    await service().revokeAccess(requireUid(request), requireString(request.data?.memberId, "memberId"));
    return { ok: true };
  }),
);

export const redeemInviteCode = onCall(options, (request) =>
  run(() => service().redeemCode(requireUid(request), requireString(request.data?.code, "code", 20))),
);

export const claimPendingInvites = onCall(options, (request) =>
  run(async () => {
    const uid = requireUid(request);
    const token = request.auth?.token;
    const claimed = await service().claimByVerifiedEmail(
      uid,
      token?.email,
      token?.email_verified === true,
    );
    return { claimed };
  }),
);

export const createSelfLinkCode = onCall(options, (request) =>
  run(() => service().createSelfLinkCode(requireUid(request))),
);
