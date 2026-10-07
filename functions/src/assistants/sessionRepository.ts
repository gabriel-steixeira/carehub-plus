/*
 * CareHub Plus — Functions / Sessões das assistentes
 *
 * Guarda, no servidor, o histórico curto e o rascunho aguardando
 * confirmação de cada conversa (pessoa × assistente × assistido × canal).
 * Como o rascunho mora aqui, o app não consegue forjar o conteúdo de uma
 * tarefa: a confirmação só executa o que a própria Cora propôs.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { FieldValue, Timestamp } from "firebase-admin/firestore";

import { ChatTurn } from "../ai/geminiClient";
import { db } from "../shared/firestore";

const HISTORY_LIMIT = 10;
const DRAFT_TTL_MS = 30 * 60 * 1000;
const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

export interface TaskDraft {
  type: "task";
  title: string;
  /** Horário local de Brasília, formato do app. */
  scheduledTime: string;
  frequency: "once" | "daily" | "weekly";
  categoryId: string;
}

export interface ChatDraft {
  type: "chat";
  title: string;
  categoryId: string;
}

export interface SosDraft {
  type: "sos";
  /** Etapa do pedido: perguntar o motivo, confirmar ou já enviado. */
  step: "reason" | "confirm" | "dispatched";
  reason: string | null;
  alertId: string | null;
}

export type Draft = TaskDraft | ChatDraft | SosDraft;

export interface Session {
  history: ChatTurn[];
  draft: Draft | null;
}

export interface SessionKey {
  principalKey: string;
  persona: "cora";
  careRecipientId: string;
  /** Muda a cada abertura da tela no app; fixo no WhatsApp. */
  sessionId: string;
}

function docId(key: SessionKey): string {
  return `${key.principalKey}_${key.persona}_${key.careRecipientId}`.replace(/\//g, "_");
}

export class SessionRepository {
  private readonly sessions = db.collection("assistant_sessions");

  async load(key: SessionKey, now = Date.now()): Promise<Session> {
    const snapshot = await this.sessions.doc(docId(key)).get();
    if (!snapshot.exists) return { history: [], draft: null };

    const updatedAt = (snapshot.get("updatedAt") as Timestamp | undefined)?.toMillis() ?? 0;
    const sameSession = snapshot.get("sessionId") === key.sessionId;
    if (!sameSession || now - updatedAt > SESSION_TTL_MS) return { history: [], draft: null };

    const draftAt = (snapshot.get("draftAt") as Timestamp | undefined)?.toMillis() ?? 0;
    const draft = (snapshot.get("draft") as Draft | null | undefined) ?? null;
    return {
      history: ((snapshot.get("history") as ChatTurn[] | undefined) ?? []).slice(-HISTORY_LIMIT),
      draft: draft && now - draftAt <= DRAFT_TTL_MS ? draft : null,
    };
  }

  /** Acrescenta o turno da pessoa e a resposta, e grava o rascunho atual. */
  async save(key: SessionKey, session: Session, turns: ChatTurn[], draftChanged: boolean): Promise<void> {
    const history = [...session.history, ...turns].slice(-HISTORY_LIMIT);
    const update: Record<string, unknown> = {
      principalKey: key.principalKey,
      persona: key.persona,
      careRecipientId: key.careRecipientId,
      sessionId: key.sessionId,
      history,
      draft: session.draft,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (draftChanged) update.draftAt = FieldValue.serverTimestamp();
    await this.sessions.doc(docId(key)).set(update, { merge: true });
  }
}
