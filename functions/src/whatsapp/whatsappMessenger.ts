/*
 * CareHub Plus — Functions / Mensageiro do WhatsApp
 *
 * Regras de negócio de envio: normaliza o telefone, respeita a cota diária
 * de cada balde (rede, SOS e Cora, separados), só manda texto livre dentro
 * da janela de 24h e registra tudo no histórico. Triggers e webhook usam
 * esta classe, nunca o cliente HTTP diretamente.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";

import {
  coraWhatsappDailyLimit,
  CUSTOMER_SERVICE_WINDOW_MS,
  sosDailyLimit,
  whatsappDailyLimit,
  whatsappGraphVersion,
  whatsappPhoneNumberId,
  whatsappToken,
} from "../config";
import { MemberContact } from "../repositories/careRepository";
import {
  ConversationContext,
  MessageLogRepository,
  QuotaBucket,
} from "../repositories/messageLogRepository";
import { maskPhone } from "../shared/firestore";
import { contactKey, toWhatsAppNumber } from "../shared/phone";
import { InteractiveButton, WhatsAppApiError, WhatsAppClient } from "./whatsappClient";
import { TEMPLATE_LANGUAGE } from "./templates";

export type SendResult =
  | "sent"
  | "invalid_phone"
  | "quota_exceeded"
  | "outside_window"
  | "failed";

export interface TemplateMessage {
  name: string;
  bodyParams: string[];
  quickReplyPayloads?: string[];
}

export type QuotaLimits = Record<QuotaBucket, number>;

/** Envio de mensagens — o webhook e os triggers dependem só disto. */
export interface Messenger {
  sendTemplate(
    member: MemberContact,
    context: ConversationContext,
    template: TemplateMessage,
    bucket?: QuotaBucket,
  ): Promise<SendResult>;
  sendTextInWindow(member: MemberContact, context: ConversationContext, body: string): Promise<SendResult>;
  replyInWindow(
    toKey: string,
    context: ConversationContext,
    body: string,
    options: { bucket: QuotaBucket; quotaKey: string; buttons?: InteractiveButton[] },
  ): Promise<SendResult>;
}

export class WhatsAppMessenger implements Messenger {
  constructor(
    private readonly client: WhatsAppClient,
    private readonly log: MessageLogRepository,
    private readonly limits: QuotaLimits,
  ) {}

  /** Template aprovado: pode ser enviado a qualquer momento. */
  async sendTemplate(
    member: MemberContact,
    context: ConversationContext,
    template: TemplateMessage,
    bucket: QuotaBucket = "network",
  ): Promise<SendResult> {
    const to = toWhatsAppNumber(member.phone);
    if (!to) {
      logger.warn("Telefone inválido para WhatsApp.", { memberId: member.id });
      return "invalid_phone";
    }
    return this.send(to, context, bucket, context.caregiverId, "template", template.name, (number) =>
      this.client.sendTemplate({
        to: number,
        templateName: template.name,
        languageCode: TEMPLATE_LANGUAGE,
        bodyParams: template.bodyParams,
        quickReplyPayloads: template.quickReplyPayloads,
      }),
    );
  }

  /** Texto livre para um membro: só sai se ele tiver escrito nas últimas 24h. */
  async sendTextInWindow(
    member: MemberContact,
    context: ConversationContext,
    body: string,
  ): Promise<SendResult> {
    const to = toWhatsAppNumber(member.phone);
    if (!to) return "invalid_phone";
    if (!(await this.insideWindow(contactKey(to)))) return "outside_window";

    return this.send(to, context, "network", context.caregiverId, "text", null, (number) =>
      this.client.sendText(number, body),
    );
  }

  /**
   * Resposta a quem acabou de escrever (Cora, convite, SOS). A janela de 24h
   * está aberta por definição; mesmo assim é conferida.
   */
  async replyInWindow(
    toKey: string,
    context: ConversationContext,
    body: string,
    options: { bucket: QuotaBucket; quotaKey: string; buttons?: InteractiveButton[] },
  ): Promise<SendResult> {
    if (!(await this.insideWindow(toKey))) return "outside_window";
    const buttons = options.buttons ?? [];
    return this.send(toKey, context, options.bucket, options.quotaKey, buttons.length ? "interactive" : "text", null, (number) =>
      buttons.length > 0
        ? this.client.sendInteractiveButtons(number, body, buttons)
        : this.client.sendText(number, body),
    );
  }

  private async insideWindow(key: string): Promise<boolean> {
    const contact = await this.log.getContact(key);
    const lastInbound = contact?.lastInboundAt?.toMillis() ?? 0;
    return Date.now() - lastInbound <= CUSTOMER_SERVICE_WINDOW_MS;
  }

  private async send(
    to: string,
    context: ConversationContext,
    bucket: QuotaBucket,
    quotaKey: string,
    kind: "template" | "text" | "interactive",
    templateName: string | null,
    deliver: (to: string) => Promise<string>,
  ): Promise<SendResult> {
    const hasQuota = await this.log.reserveQuota(bucket, quotaKey, this.limits[bucket]);
    if (!hasQuota) {
      logger.warn("Cota diária de WhatsApp atingida.", { bucket });
      return "quota_exceeded";
    }

    try {
      const wamid = await deliver(to);
      await this.log.logOutbound(wamid, to, contactKey(to), context, kind, templateName);
      logger.info("WhatsApp enviado.", { to: maskPhone(to), kind, bucket, templateName });
      return "sent";
    } catch (error) {
      const apiError = error instanceof WhatsAppApiError ? error : null;
      const reason = error instanceof Error ? error.message : String(error);
      await this.log.logOutboundFailure(to, context, reason, apiError?.code ?? null);
      logger.error("Falha ao enviar WhatsApp.", {
        to: maskPhone(to),
        code: apiError?.code,
        reason,
      });
      return "failed";
    }
  }
}

/** Monta o mensageiro lendo segredos e parâmetros em tempo de execução. */
export function createMessenger(): WhatsAppMessenger {
  const client = new WhatsAppClient({
    token: whatsappToken.value(),
    phoneNumberId: whatsappPhoneNumberId.value(),
    apiVersion: whatsappGraphVersion.value(),
  });
  return new WhatsAppMessenger(client, new MessageLogRepository(), {
    network: whatsappDailyLimit.value(),
    sos: sosDailyLimit.value(),
    cora: coraWhatsappDailyLimit.value(),
  });
}
