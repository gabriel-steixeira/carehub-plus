/*
 * CareHub Plus — Functions / Cliente da WhatsApp Cloud API
 *
 * Único ponto do backend que conversa com a Graph API da Meta. Triggers e
 * webhook não montam requisições HTTP: chamam este cliente, que pode ser
 * trocado por outro canal (Telegram, Evolution) sem mexer no resto.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

const REQUEST_TIMEOUT_MS = 10_000;

// Limites da Meta para mensagens interativas com botões.
const MAX_BUTTONS = 3;
const MAX_BUTTON_TITLE = 20;
const MAX_BUTTON_ID = 256;
const MAX_INTERACTIVE_BODY = 1024;

export interface InteractiveButton {
  id: string;
  title: string;
}

function truncate(text: string, max: number): string {
  return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

export interface WhatsAppClientOptions {
  token: string;
  phoneNumberId: string;
  apiVersion: string;
}

export interface SendTemplateInput {
  to: string;
  templateName: string;
  languageCode: string;
  /** Valores de {{1}}, {{2}}... na ordem do corpo do template. */
  bodyParams: string[];
  /** Payload devolvido no webhook quando a pessoa toca em cada botão. */
  quickReplyPayloads?: string[];
}

/** Erro retornado pela Meta, com o código para diagnóstico. */
export class WhatsAppApiError extends Error {
  constructor(
    message: string,
    readonly httpStatus: number,
    readonly code?: number,
  ) {
    super(message);
    this.name = "WhatsAppApiError";
  }
}

interface GraphSendResponse {
  messages?: { id: string }[];
  error?: { message?: string; code?: number };
}

export class WhatsAppClient {
  constructor(private readonly options: WhatsAppClientOptions) {}

  /** Envia um template aprovado. Devolve o id da mensagem (wamid). */
  async sendTemplate(input: SendTemplateInput): Promise<string> {
    const components: Record<string, unknown>[] = [
      {
        type: "body",
        parameters: input.bodyParams.map((text) => ({ type: "text", text })),
      },
    ];

    (input.quickReplyPayloads ?? []).forEach((payload, index) => {
      components.push({
        type: "button",
        sub_type: "quick_reply",
        index: String(index),
        parameters: [{ type: "payload", payload }],
      });
    });

    return this.post({
      messaging_product: "whatsapp",
      to: input.to,
      type: "template",
      template: {
        name: input.templateName,
        language: { code: input.languageCode },
        components,
      },
    });
  }

  /** Texto livre — a Meta só aceita dentro da janela de 24h. */
  async sendText(to: string, body: string): Promise<string> {
    return this.post({
      messaging_product: "whatsapp",
      to,
      type: "text",
      text: { body, preview_url: false },
    });
  }

  /**
   * Texto com até 3 botões de resposta (só dentro da janela de 24h). O `id`
   * de cada botão volta no webhook como `interactive.button_reply.id`.
   */
  async sendInteractiveButtons(to: string, body: string, buttons: InteractiveButton[]): Promise<string> {
    const safeButtons = buttons.slice(0, MAX_BUTTONS).map((button) => ({
      type: "reply",
      reply: {
        id: button.id.slice(0, MAX_BUTTON_ID),
        title: truncate(button.title, MAX_BUTTON_TITLE),
      },
    }));
    return this.post({
      messaging_product: "whatsapp",
      to,
      type: "interactive",
      interactive: {
        type: "button",
        body: { text: truncate(body, MAX_INTERACTIVE_BODY) },
        action: { buttons: safeButtons },
      },
    });
  }

  private async post(payload: Record<string, unknown>): Promise<string> {
    const { apiVersion, phoneNumberId, token } = this.options;
    const url = `https://graph.facebook.com/${apiVersion}/${phoneNumberId}/messages`;

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });

    const data = (await response.json().catch(() => ({}))) as GraphSendResponse;
    const messageId = data.messages?.[0]?.id;

    if (!response.ok || !messageId) {
      throw new WhatsAppApiError(
        data.error?.message ?? `Falha ao enviar mensagem (HTTP ${response.status}).`,
        response.status,
        data.error?.code,
      );
    }
    return messageId;
  }
}
