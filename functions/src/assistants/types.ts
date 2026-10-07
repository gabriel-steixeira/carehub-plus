/*
 * CareHub Plus — Functions / Tipos das assistentes
 *
 * Formato de resposta comum à Cora no app e no WhatsApp: um texto e até
 * alguns atalhos (rótulo + intenção estável). O canal decide como desenhar
 * os atalhos (chips no app, botões no WhatsApp).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

export interface QuickReply {
  label: string;
  intent: string;
}

export interface AssistantReply {
  text: string;
  quickReplies: QuickReply[];
  /** Ação que o canal precisa executar depois da resposta (ex.: SOS). */
  action?: { type: "sos_offer" };
  /** A cota diária de IA acabou (o WhatsApp avisa só uma vez por dia). */
  quotaExceeded?: boolean;
}
