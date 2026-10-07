/*
 * CareHub Plus — Functions / Porteiro do WhatsApp
 *
 * Decide o destino de cada mensagem recebida, nesta ordem:
 *   1. botão de SOS ou de tarefa (fluxo da rede de apoio, sem mudança);
 *   2. "ENTRAR <código>" (aceite de convite, sem Gemini);
 *   3. número conhecido e autorizado → Cora;
 *   4. número conhecido sem acesso pelo WhatsApp → aviso, no máximo 1x/dia;
 *   5. número desconhecido → ignorado, sem resposta e sem Gemini.
 * Nenhuma mensagem do WhatsApp vai para o chat do app.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";

import { AccessService } from "../access/accessService";
import { GrantRepository } from "../access/grantRepository";
import { InviteService, parseEntryCommand, WhatsAppAcceptResult } from "../access/inviteService";
import { Identity } from "../access/types";
import { CareRepository, MemberContact } from "../repositories/careRepository";
import { ConversationContext, MessageLogRepository } from "../repositories/messageLogRepository";
import { DailyLimiter } from "../shared/dailyLimiter";
import { db, maskPhone } from "../shared/firestore";
import { contactKey } from "../shared/phone";
import { firstName } from "../shared/text";
import { CoraWhatsAppChannel } from "../whatsapp/coraWhatsAppChannel";
import { ButtonAction, ButtonPayload, parsePayload } from "../whatsapp/templates";
import { Messenger } from "../whatsapp/whatsappMessenger";

// Formato (parcial) do corpo enviado pela Meta.
export interface IncomingMessage {
  id: string;
  from: string;
  type: string;
  text?: { body?: string };
  button?: { text?: string; payload?: string };
  interactive?: { button_reply?: { id?: string; title?: string } };
}

export interface IncomingStatus {
  id: string;
  status: string;
  errors?: { code?: number; title?: string; message?: string }[];
}

/** Botões da Cora usam a intenção como id ("cora.task.create.confirm"). */
const CORA_INTENT_PREFIX = "cora.";

export const NO_WHATSAPP_ACCESS =
  "Seu acesso atual não inclui o WhatsApp. Use o app CareHub Plus para acompanhar os cuidados.";

export function readonlyNotice(recipientFirstName: string): string {
  return (
    `Seu acesso a ${recipientFirstName} é apenas de visualização e não inclui o WhatsApp. ` +
    "Use o código na tela 'Tenho um convite' do app CareHub Plus."
  );
}

const ENTRY_REPLIES: Record<WhatsAppAcceptResult["kind"], (name: string) => string> = {
  accepted: (name) =>
    `Pronto! Agora você acompanha os cuidados de ${name} pelo WhatsApp. ` +
    "Pode me perguntar sobre a rotina e as tarefas, pedir um lembrete ou mandar SOS em uma emergência.",
  self_linked: () =>
    "Pronto! Seu WhatsApp está ligado à sua conta do CareHub Plus. " +
    "Pode me perguntar sobre a rotina e as tarefas, pedir um lembrete ou mandar SOS em uma emergência.",
  readonly: (name) => readonlyNotice(name),
  invalid: () => "Código inválido ou vencido. Peça um novo convite a quem cadastrou você.",
  rate_limited: () => "Muitas tentativas hoje. Tente de novo amanhã ou peça um novo convite.",
};

export interface RouterDependencies {
  messenger: Messenger;
  cora: CoraWhatsAppChannel;
  invites: InviteService;
  care?: CareRepository;
  log?: MessageLogRepository;
  access?: AccessService;
  grants?: GrantRepository;
  limiter?: DailyLimiter;
}

export class InboundRouter {
  private readonly care: CareRepository;
  private readonly log: MessageLogRepository;
  private readonly access: AccessService;
  private readonly grants: GrantRepository;
  private readonly limiter: DailyLimiter;

  constructor(private readonly deps: RouterDependencies) {
    this.care = deps.care ?? new CareRepository();
    this.log = deps.log ?? new MessageLogRepository();
    this.access = deps.access ?? new AccessService();
    this.grants = deps.grants ?? new GrantRepository();
    this.limiter = deps.limiter ?? new DailyLimiter();
  }

  async safely(work: () => Promise<void>): Promise<void> {
    try {
      await work();
    } catch (error) {
      logger.error("Erro ao processar evento do webhook.", {
        reason: error instanceof Error ? error.message : String(error),
      });
    }
  }

  async handleStatus(status: IncomingStatus): Promise<void> {
    const error = status.errors?.[0];
    await this.log.updateDeliveryStatus(status.id, status.status, error?.code ?? null, error?.message ?? error?.title ?? null);
  }

  async handleMessage(message: IncomingMessage): Promise<void> {
    const key = contactKey(message.from);
    const { text, payload } = readContent(message);
    const contact = await this.log.getContact(key);

    const isNew = await this.log.saveInboundIfNew(message.id, message.from, key, text, payload, contact);
    if (!isNew) return; // a Meta reenviou um evento que já foi tratado
    await this.log.touchInbound(key);

    // 1) Botões dos templates de SOS e de tarefa.
    const button = parsePayload(payload);
    if (button) {
      await this.handleButton(button);
      return;
    }

    // 2) Aceite de convite — a única coisa que um número novo pode fazer.
    const code = parseEntryCommand(text);
    if (code) {
      const result = await this.deps.invites.acceptByWhatsApp(code, key);
      const name = "recipientFirstName" in result ? result.recipientFirstName : "";
      await this.replyPlain(key, ENTRY_REPLIES[result.kind](name));
      return;
    }

    // 3) Quem é este número, e o que ele pode fazer pelo WhatsApp?
    const identity = await this.identify(key);
    const accessible = await this.access.listAccessible(identity, "whatsapp");
    if (accessible.length > 0) {
      const intent = payload?.startsWith(CORA_INTENT_PREFIX) ? payload : null;
      await this.deps.cora.handle({ identity, fromKey: key, text, intent, accessible });
      return;
    }

    // 4) Conhecido, mas sem acesso pelo WhatsApp (ex.: Apenas Visualização).
    const known = await this.knownWithoutAccess(identity);
    if (known) {
      if (await this.limiter.markOnce("notice", `wa:${key}`, "no_whatsapp_access")) {
        await this.replyPlain(key, known.recipientFirstName ? readonlyNotice(known.recipientFirstName) : NO_WHATSAPP_ACCESS);
      }
      return;
    }

    // 5) Desconhecido: nada de Gemini, nada de resposta.
    logger.info("Mensagem de número desconhecido ignorada.", { from: maskPhone(key), type: message.type });
  }

  /** Conta ligada ao número (dona que ativou o próprio WhatsApp). */
  private async identify(key: string): Promise<Identity> {
    const link = await db.collection("owner_whatsapp_links").doc(key).get();
    return { uid: (link.get("uid") as string | undefined) ?? null, contactKey: key };
  }

  private async knownWithoutAccess(identity: Identity): Promise<{ recipientFirstName: string | null } | null> {
    if (identity.uid) return { recipientFirstName: null };
    const grants = await this.grants.findAnyByContactKey(identity.contactKey ?? "");
    if (grants.length === 0) return null;
    const readonly = grants.find((grant) => grant.status === "active" && grant.accessLevel === "readonly");
    const name = readonly ? await this.care.getCareRecipientName(readonly.careRecipientId) : null;
    return { recipientFirstName: name ? firstName(name) : null };
  }

  private async replyPlain(key: string, text: string): Promise<void> {
    const context: ConversationContext = {
      memberId: "",
      memberName: "",
      caregiverId: "",
      careRecipientId: null,
      relatedType: "cora",
      relatedId: `wa:${key}`,
    };
    await this.deps.messenger.replyInWindow(key, context, text, { bucket: "cora", quotaKey: `wa:${key}` });
  }

  private async handleButton(button: ButtonPayload): Promise<void> {
    const member = await this.care.getMember(button.memberId);
    if (!member?.caregiverId) return;

    const isTask = button.action === ButtonAction.taskAccept || button.action === ButtonAction.taskDecline;

    let reply: string | null = null;
    if (isTask) {
      const accepted = button.action === ButtonAction.taskAccept;
      const saved = await this.care.setTaskAssignmentResponse(button.targetId, member.id, accepted ? "accepted" : "declined");
      if (saved) {
        reply = accepted
          ? `Obrigado, ${firstName(member.name)}! A tarefa ficou com você.`
          : "Tudo bem, obrigado por avisar. Vamos repassar a tarefa.";
      }
    } else {
      const result = await this.care.registerSosResponse(button.targetId, member.id, button.action === ButtonAction.sosAccept);
      reply = {
        accepted_first: "Obrigado! Avisamos que você está a caminho.",
        already_accepted: "Obrigado! Outra pessoa da rede já está a caminho.",
        declined: "Tudo bem, obrigado por responder.",
        not_allowed: null,
      }[result];
    }

    if (reply) {
      await this.deps.messenger.sendTextInWindow(member, contextFor(member, isTask ? "task" : "sos", button.targetId), reply);
    }
  }
}

function readContent(message: IncomingMessage): { text: string; payload: string | null } {
  switch (message.type) {
    case "text":
      return { text: message.text?.body ?? "", payload: null };
    case "button":
      return { text: message.button?.text ?? "", payload: message.button?.payload ?? null };
    case "interactive":
      return {
        text: message.interactive?.button_reply?.title ?? "",
        payload: message.interactive?.button_reply?.id ?? null,
      };
    default:
      // Áudio, imagem etc. ficam registrados, mas não são processados.
      return { text: `[${message.type}]`, payload: null };
  }
}

function contextFor(member: MemberContact, relatedType: ConversationContext["relatedType"], relatedId: string): ConversationContext {
  return {
    memberId: member.id,
    memberName: member.name,
    caregiverId: member.caregiverId ?? "",
    careRecipientId: member.careRecipientId,
    relatedType,
    relatedId,
  };
}
