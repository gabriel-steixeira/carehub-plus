/*
 * CareHub Plus — Functions / Cora no WhatsApp
 *
 * Liga o WhatsApp ao mesmo cérebro da Cora do app. Cuida do que só existe
 * neste canal: escolher de qual assistido falar, o atalho de SOS, as
 * respostas SIM/NÃO às confirmações e o envio com botões. Só é chamado
 * pelo porteiro depois que o número foi identificado e autorizado.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import { Identity, principalKey, ResolvedAccess } from "../access/types";
import { CoraAccessError, CoraBrain, CoraIntents } from "../assistants/cora/coraBrain";
import { SessionKey, SessionRepository } from "../assistants/sessionRepository";
import { AssistantReply } from "../assistants/types";
import { ConversationContext, QuotaBucket } from "../repositories/messageLogRepository";
import { DailyLimiter } from "../shared/dailyLimiter";
import { db } from "../shared/firestore";
import { firstName } from "../shared/text";
import {
  choicesMessage,
  isSwitchCommand,
  normalize,
  parseChoice,
  parseSwitchRequest,
} from "./recipientSelector";
import { SosConversation } from "./sosConversation";
import { Messenger } from "./whatsappMessenger";

/** O WhatsApp tem uma conversa contínua por pessoa e assistido. */
const WHATSAPP_SESSION_ID = "whatsapp";

export interface InboundTurn {
  identity: Identity;
  fromKey: string;
  text: string;
  /** Id do botão tocado, quando a mensagem veio de um botão nosso. */
  intent: string | null;
  /** Assistidos que esta pessoa pode acompanhar pelo WhatsApp (já filtrados). */
  accessible: ResolvedAccess[];
}

export class CoraWhatsAppChannel {
  private readonly participants = db.collection("whatsapp_participants");

  constructor(
    private readonly brain: CoraBrain,
    private readonly sos: SosConversation,
    private readonly messenger: Messenger,
    private readonly sessions = new SessionRepository(),
    private readonly limiter = new DailyLimiter(),
  ) {}

  async handle(turn: InboundTurn): Promise<void> {
    const access = await this.selectRecipient(turn);
    if (!access) return;

    const key: SessionKey = {
      principalKey: principalKey(turn.identity),
      persona: "cora",
      careRecipientId: access.careRecipientId,
      sessionId: WHATSAPP_SESSION_ID,
    };

    // 1) SOS primeiro, sem IA: funciona com a cota de IA esgotada.
    const session = await this.sessions.load(key);
    const draftBefore = JSON.stringify(session.draft);
    const sosReply = await this.sos.handle({
      identity: turn.identity,
      access,
      text: turn.text,
      intent: turn.intent,
      session,
      fromKey: turn.fromKey,
    });
    if (sosReply) {
      await this.sessions.save(key, session, [
        { role: "user", text: turn.text },
        { role: "model", text: sosReply.text },
      ], true);
      await this.send(turn, access, sosReply, "sos", access.ownerId);
      return;
    }
    if (JSON.stringify(session.draft) !== draftBefore) {
      await this.sessions.save(key, session, [], true);
    }

    // 2) SIM/NÃO respondem a uma confirmação pendente da Cora.
    const intent = turn.intent ?? this.confirmationIntent(turn.text, session.draft?.type);

    // 3) A Cora de sempre.
    let reply: AssistantReply;
    try {
      reply = await this.brain.reply({
        identity: turn.identity,
        careRecipientId: access.careRecipientId,
        text: turn.text,
        intent,
        channel: "whatsapp",
        sessionId: WHATSAPP_SESSION_ID,
      });
    } catch (error) {
      if (error instanceof CoraAccessError) return; // acesso caiu no meio do caminho
      throw error;
    }

    if (reply.quotaExceeded) {
      const first = await this.limiter.markOnce("notice", principalKey(turn.identity), "ai_quota");
      if (!first) return; // já avisou hoje: silêncio
    }
    await this.send(turn, access, reply, "cora", principalKey(turn.identity));
  }

  /** Decide o assistido da conversa. `null` quando a mensagem foi a pergunta. */
  private async selectRecipient(turn: InboundTurn): Promise<ResolvedAccess | null> {
    const ref = this.participants.doc(turn.fromKey);
    const state = (await ref.get()).data() ?? {};
    const options = turn.accessible;
    const selected = options.find((option) => option.careRecipientId === state.selectedCareRecipientId);

    const choose = async (option: ResolvedAccess, announce: boolean): Promise<ResolvedAccess | null> => {
      await ref.set(
        { contactKey: turn.fromKey, selectedCareRecipientId: option.careRecipientId, awaitingChoice: false, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      if (!announce) return option;
      await this.sendText(turn, option, `Certo, agora falamos sobre ${firstName(option.careRecipientName)}. Como posso ajudar?`);
      return null;
    };

    const ask = async (): Promise<null> => {
      await ref.set({ contactKey: turn.fromKey, awaitingChoice: true, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      await this.sendText(turn, options[0], choicesMessage(options));
      return null;
    };

    if (options.length === 1) {
      if (isSwitchCommand(turn.text)) {
        await this.sendText(turn, options[0], `Por aqui você acompanha só ${firstName(options[0].careRecipientName)}.`);
        return null;
      }
      return selected ? selected : choose(options[0], false);
    }

    if (isSwitchCommand(turn.text)) return ask();

    const switchTo = parseSwitchRequest(turn.text, options);
    if (switchTo) return choose(switchTo, true);

    if (state.awaitingChoice === true || !selected) {
      const picked = parseChoice(turn.text, options);
      return picked ? choose(picked, true) : ask();
    }
    return selected;
  }

  private confirmationIntent(text: string, draftType: string | undefined): string | null {
    const clean = normalize(text);
    const yes = /^(sim|s|confirmar|confirmo|pode|ok)$/.test(clean);
    const no = /^(nao|n|cancelar)$/.test(clean);
    if (draftType === "task") return yes ? CoraIntents.confirmTask : no ? CoraIntents.cancelTask : null;
    if (draftType === "chat") return no ? CoraIntents.cancelChat : null;
    return null;
  }

  private context(turn: InboundTurn, access: ResolvedAccess): ConversationContext {
    return {
      memberId: "",
      memberName: "",
      caregiverId: access.ownerId,
      careRecipientId: access.careRecipientId,
      relatedType: "cora",
      relatedId: principalKey(turn.identity),
    };
  }

  private async sendText(turn: InboundTurn, access: ResolvedAccess, text: string): Promise<void> {
    await this.messenger.replyInWindow(turn.fromKey, this.context(turn, access), text, {
      bucket: "cora",
      quotaKey: principalKey(turn.identity),
    });
  }

  private async send(
    turn: InboundTurn,
    access: ResolvedAccess,
    reply: AssistantReply,
    bucket: QuotaBucket,
    quotaKey: string,
  ): Promise<void> {
    const result = await this.messenger.replyInWindow(turn.fromKey, this.context(turn, access), reply.text, {
      bucket,
      quotaKey,
      buttons: reply.quickReplies.slice(0, 3).map((quick) => ({ id: quick.intent, title: quick.label })),
    });
    if (result !== "sent") logger.info("Resposta da Cora não enviada.", { result, bucket });
  }
}
