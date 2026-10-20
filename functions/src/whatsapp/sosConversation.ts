/*
 * CareHub Plus — Functions / SOS pela Cora no WhatsApp
 *
 * Pedido de ajuda em três passos: motivo (ou pular), confirmação e envio.
 * Palavras como "SOS" e "socorro" abrem o fluxo SEM chamar o Gemini, para
 * funcionar mesmo com a IA fora do ar ou a cota de IA esgotada. O alerta é
 * gravado no mesmo formato do app e o trigger atual avisa a rede, usando a
 * cota própria do SOS.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";

import { GrantRepository } from "../access/grantRepository";
import { canRequestSos, Identity, principalKey, ResolvedAccess } from "../access/types";
import { SosDraft, Session } from "../assistants/sessionRepository";
import { AssistantReply, QuickReply } from "../assistants/types";
import { AppNotifier } from "../notifications/appNotifier";
import { CareRepository } from "../repositories/careRepository";
import { DailyLimiter } from "../shared/dailyLimiter";
import { db } from "../shared/firestore";
import { contactKey, toWhatsAppNumber } from "../shared/phone";
import { firstName, localIsoNow, templateParam } from "../shared/text";
import { normalize } from "./recipientSelector";

export const SosIntents = {
  start: "cora.sos.start",
  skip: "cora.sos.skip",
  confirm: "cora.sos.confirm",
  cancel: "cora.sos.cancel",
} as const;

const SAMU = "Se for uma emergência médica, ligue 192 (SAMU).";
const MAX_NOTIFIED = 10;
const DEFAULT_REASON = "Pedido de ajuda pelo WhatsApp";

const SKIP: QuickReply = { label: "Pular", intent: SosIntents.skip };
const CANCEL: QuickReply = { label: "Cancelar", intent: SosIntents.cancel };
const CONFIRM: QuickReply = { label: "✅ Confirmar SOS", intent: SosIntents.confirm };

/** Palavras que abrem o SOS sem passar pela IA. */
export function isSosKeyword(text: string): boolean {
  return /^(sos|socorro|emergencia|preciso de ajuda|ajuda urgente)\b/.test(normalize(text));
}

function isYes(text: string): boolean {
  return /^(sim|s|confirmar|confirmo|ok)$/.test(normalize(text));
}

function isCancel(text: string): boolean {
  return /^(cancelar|nao|n)$/.test(normalize(text));
}

export interface SosInput {
  identity: Identity;
  access: ResolvedAccess;
  text: string;
  intent: string | null;
  session: Session;
  /** Chave do número que escreveu (para não avisar a própria pessoa). */
  fromKey: string;
}

export class SosConversation {
  constructor(
    private readonly sosRequestsPerDay: number,
    private readonly care = new CareRepository(),
    private readonly grants = new GrantRepository(),
    private readonly notifier = new AppNotifier(),
    private readonly limiter = new DailyLimiter(),
    private readonly now: () => Date = () => new Date(),
  ) {}

  /**
   * Trata a mensagem se ela faz parte do SOS. Devolve `null` quando não é
   * assunto de SOS (aí a Cora responde normalmente). Altera `session.draft`.
   */
  async handle(input: SosInput): Promise<AssistantReply | null> {
    const draft = input.session.draft?.type === "sos" ? input.session.draft : null;
    const starts = input.intent === SosIntents.start || isSosKeyword(input.text);

    if (!draft) return starts ? this.start(input) : null;

    if (draft.step === "dispatched") {
      // Depois de enviado, só "CANCELAR" explícito cancela: um "não" dito à
      // Cora em outra conversa não pode derrubar um pedido de ajuda.
      if (input.intent === SosIntents.cancel || normalize(input.text) === "cancelar") {
        return this.cancel(input, draft);
      }
      if (starts) return this.start(input);
      input.session.draft = null;
      return null;
    }

    if (input.intent === SosIntents.start) return this.start(input);
    if (input.intent === SosIntents.cancel || isCancel(input.text)) return this.cancel(input, draft);

    if (draft.step === "reason") {
      const reason =
        input.intent === SosIntents.skip || /^pular$/.test(normalize(input.text))
          ? DEFAULT_REASON
          : templateParam(input.text, 120);
      input.session.draft = { ...draft, step: "confirm", reason };
      return {
        text: `Confirma o pedido de ajuda para ${firstName(input.access.careRecipientName)}? Motivo: ${reason}. ${SAMU}`,
        quickReplies: [CONFIRM, CANCEL],
      };
    }

    if (input.intent === SosIntents.confirm || isYes(input.text)) return this.dispatch(input, draft);
    return {
      text: `Responda SIM para avisar a rede de apoio ou CANCELAR para desistir. ${SAMU}`,
      quickReplies: [CONFIRM, CANCEL],
    };
  }

  private start(input: SosInput): AssistantReply {
    if (!canRequestSos(input.access)) {
      input.session.draft = null;
      return {
        text: `Seu nível de acesso não inclui pedir SOS por aqui. ${SAMU}`,
        quickReplies: [],
      };
    }
    input.session.draft = { type: "sos", step: "reason", reason: null, alertId: null };
    return {
      text:
        `Vou avisar a rede de apoio de ${firstName(input.access.careRecipientName)}. ` +
        "Em uma frase, o que está acontecendo? Se preferir, toque em Pular.",
      quickReplies: [SKIP, CANCEL],
    };
  }

  private async cancel(input: SosInput, draft: SosDraft): Promise<AssistantReply> {
    input.session.draft = null;
    if (draft.step !== "dispatched" || !draft.alertId) {
      return { text: "Tudo bem, não avisei ninguém. Se precisar, é só mandar SOS.", quickReplies: [] };
    }

    const ref = db.collection("sos_alerts").doc(draft.alertId);
    const snapshot = await ref.get();
    if (snapshot.exists && ["pending", "dispatched", "accepted"].includes(snapshot.get("status") as string)) {
      await ref.update({ status: "cancelled", updatedAt: localIsoNow(this.now()) });
    }
    return { text: "Pedido de ajuda cancelado.", quickReplies: [] };
  }

  private async dispatch(input: SosInput, draft: SosDraft): Promise<AssistantReply> {
    const key = principalKey(input.identity);
    if (!(await this.limiter.tryConsume("sos_request", key, this.sosRequestsPerDay))) {
      input.session.draft = null;
      return {
        text: `Você já abriu vários pedidos de ajuda hoje. Use o app ou ligue para alguém da rede. ${SAMU}`,
        quickReplies: [],
      };
    }

    const { access } = input;
    const requester = await this.requester(input);
    const members = await db
      .collection("network_members")
      .where("careRecipientId", "==", access.careRecipientId)
      .get();
    const notified = members.docs
      .filter((doc) => doc.get("caregiverId") === access.ownerId)
      .filter((doc) => doc.id !== requester.memberId && !this.isSameNumber(doc.get("phone"), input.fromKey))
      .map((doc) => doc.id)
      .slice(0, MAX_NOTIFIED);

    // O dono é um destinatário especial quando quem pede não é o próprio dono.
    const notifyOwner = access.role !== "owner";
    const recipient = firstName(access.careRecipientName);
    if (notified.length === 0 && !notifyOwner) {
      input.session.draft = null;
      return {
        text: `Não encontrei ninguém na rede de apoio de ${recipient} para avisar. ${SAMU}`,
        quickReplies: [],
      };
    }

    const ownerContact = notifyOwner ? await this.care.getOwnerContact(access.ownerId) : null;
    const ownerChannel = ownerContact?.sosChannel ?? "app";

    const alertId = `sos_${this.now().getTime()}`;
    const now = localIsoNow(this.now());
    const reason = draft.reason ?? DEFAULT_REASON;
    await db.collection("sos_alerts").doc(alertId).set({
      id: alertId,
      caregiverId: access.ownerId,
      careRecipientId: access.careRecipientId,
      taskId: null,
      taskTitle: reason,
      notifiedMemberIds: notified,
      // O dono nunca entra em notifiedMemberIds; é avisado pelo trigger via
      // notifyOwner/ownerChannel (app sempre; WhatsApp só quando escolhido).
      ...(notifyOwner ? { notifyOwner: true, ownerChannel } : {}),
      // Direto em "dispatched": a confirmação no WhatsApp já fez o papel da
      // janela de cancelamento do app. O trigger atual faz o envio.
      status: "dispatched",
      createdAt: now,
      updatedAt: now,
      requestedBy: key,
      requestedByName: requester.name,
      channel: "whatsapp",
    });
    input.session.draft = { ...draft, step: "dispatched", alertId };

    if (access.role !== "owner") {
      await this.notifier.notifyUid(access.ownerId, {
        type: "sos",
        title: "SOS aberto pelo WhatsApp",
        body: `${requester.name ? firstName(requester.name) : "Alguém da rede"} pediu ajuda para ${recipient}: ${reason}.`,
        relatedId: alertId,
        caregiverId: access.ownerId,
        careRecipientId: access.careRecipientId,
      });
    }

    logger.info("SOS aberto pela Cora no WhatsApp.", { alertId, notified: notified.length, notifyOwner });
    return {
      text:
        `${this.dispatchSummary(notified.length, notifyOwner, recipient)} ` +
        `Para cancelar, mande CANCELAR. ${SAMU}`,
      quickReplies: [CANCEL],
    };
  }

  /**
   * Texto de confirmação contando quantas pessoas serão avisadas. O dono do
   * perfil (quando notifyOwner) conta como mais uma pessoa — avisada pelo app.
   */
  private dispatchSummary(notifiedCount: number, notifyOwner: boolean, recipient: string): string {
    if (notifiedCount === 0 && notifyOwner) {
      return `Pronto, avisei o responsável pelo perfil de ${recipient} pelo app.`;
    }
    const total = notifiedCount + (notifyOwner ? 1 : 0);
    return `Pronto, estou avisando ${total} ${total === 1 ? "pessoa" : "pessoas"} da rede de apoio de ${recipient}.`;
  }

  /** Nome e membro de quem pediu: a dona ou o membro da concessão. */
  private async requester(input: SosInput): Promise<{ name: string | null; memberId: string | null }> {
    if (input.access.role === "owner") {
      return { name: await this.care.getCaregiverName(input.access.ownerId), memberId: null };
    }
    const grant = input.access.grantId ? await this.grants.get(input.access.grantId) : null;
    const member = grant ? await this.care.getMember(grant.memberId) : null;
    return { name: member?.name ?? null, memberId: grant?.memberId ?? null };
  }

  private isSameNumber(phone: unknown, fromKey: string): boolean {
    const number = toWhatsAppNumber(typeof phone === "string" ? phone : null);
    return !!number && contactKey(number) === fromKey;
  }
}
