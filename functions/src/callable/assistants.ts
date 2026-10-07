/*
 * CareHub Plus — Functions / Callables das assistentes
 *
 * - coraChat: uma mensagem para a Cora. O backend confere o acesso ao
 *   assistido, guarda o histórico e o rascunho e chama o Gemini.
 * - tokeInterpret: triagem do Toke com o Gemini; as regras da conta ficam
 *   no app.
 * As duas exigem login e somam na mesma cota diária de IA por pessoa. A
 * chave do Gemini existe só aqui (Secret Manager).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import { ChatTurn, GeminiClient, GeminiError } from "../ai/geminiClient";
import { CoraAccessError, CoraBrain } from "../assistants/cora/coraBrain";
import { SupportContext, TokeInterpreter } from "../assistants/toke/tokeInterpreter";
import { aiDailyLimit, geminiApiKey, geminiModel, REGION } from "../config";
import { DailyLimiter } from "../shared/dailyLimiter";

const MAX_TEXT = 2000;
const MAX_HISTORY = 10;

function generator(): GeminiClient {
  return new GeminiClient({ apiKey: geminiApiKey.value(), model: geminiModel.value() });
}

function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Entre na sua conta para continuar.");
  return uid;
}

function optionalString(value: unknown, max: number): string | null {
  return typeof value === "string" && value.trim() ? value.trim().slice(0, max) : null;
}

function requiredString(value: unknown, field: string, max: number): string {
  const text = optionalString(value, max);
  if (!text) throw new HttpsError("invalid-argument", `Campo "${field}" inválido.`);
  return text;
}

const options = { region: REGION, maxInstances: 5, secrets: [geminiApiKey], timeoutSeconds: 90 };

export const coraChat = onCall(options, async (request) => {
  const uid = requireUid(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const careRecipientId = requiredString(data.careRecipientId, "careRecipientId", 200);
  const sessionId = requiredString(data.sessionId, "sessionId", 100);
  const intent = optionalString(data.intent, 100);
  const text = optionalString(data.text, MAX_TEXT) ?? "";
  if (!text && !intent) throw new HttpsError("invalid-argument", "Mensagem vazia.");

  const categories =
    data.categories && typeof data.categories === "object" ? (data.categories as Record<string, string>) : undefined;

  try {
    return await new CoraBrain({ generator: generator(), aiDailyLimit: aiDailyLimit.value() }).reply({
      identity: { uid, contactKey: null },
      careRecipientId,
      text,
      intent,
      channel: "app",
      sessionId,
      categories,
    });
  } catch (error) {
    if (error instanceof CoraAccessError) throw new HttpsError("permission-denied", error.message);
    logger.error("coraChat falhou.", { reason: error instanceof Error ? error.message : String(error) });
    throw new HttpsError("internal", "Não consegui consultar a Cora agora. Tente novamente em instantes.");
  }
});

function readHistory(value: unknown): ChatTurn[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is { role?: unknown; text?: unknown } => typeof item === "object" && item !== null)
    .map((item) => ({
      role: item.role === "model" ? ("model" as const) : ("user" as const),
      text: optionalString(item.text, MAX_TEXT) ?? "",
    }))
    .filter((turn) => turn.text)
    .slice(-MAX_HISTORY);
}

function readSupportContext(value: unknown): SupportContext {
  if (!value || typeof value !== "object") return { contextAvailable: false };
  const raw = value as Record<string, unknown>;
  if (raw.contextAvailable === false) return { contextAvailable: false };
  return {
    contextAvailable: true,
    userName: optionalString(raw.userName, 120),
    currentPlan: optionalString(raw.currentPlan, 120),
    subscription: optionalString(raw.subscription, 300),
    pendencies: optionalString(raw.pendencies, 500),
    catalog: optionalString(raw.catalog, 3000),
  };
}

export const tokeInterpret = onCall(options, async (request) => {
  const uid = requireUid(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const text = requiredString(data.text, "text", MAX_TEXT);
  const planIds = Array.isArray(data.planIds)
    ? data.planIds.filter((id): id is string => typeof id === "string" && /^[\w-]{1,60}$/.test(id)).slice(0, 20)
    : [];

  if (!(await new DailyLimiter("ai_quota").tryConsume("ai", `uid:${uid}`, aiDailyLimit.value()))) {
    throw new HttpsError("resource-exhausted", "Você atingiu o limite de conversas de hoje. Volte amanhã.");
  }

  try {
    return await new TokeInterpreter(generator()).interpret({
      text,
      history: readHistory(data.history),
      context: readSupportContext(data.context),
      planIds,
    });
  } catch (error) {
    if (error instanceof GeminiError) throw new HttpsError("unavailable", error.message);
    logger.error("tokeInterpret falhou.", { reason: error instanceof Error ? error.message : String(error) });
    throw new HttpsError("internal", "Não consegui consultar o Toke agora. Tente novamente em instantes.");
  }
});
