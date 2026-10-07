/*
 * CareHub Plus — Functions / Templates do WhatsApp
 *
 * Nomes dos templates aprovados no WhatsApp Manager e o formato dos
 * payloads dos botões. Mensagens iniciadas pelo app (fora da janela de
 * 24h) só podem usar templates aprovados pela Meta.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

export const TEMPLATE_LANGUAGE = "pt_BR";

/**
 * Corpo cadastrado na Meta (categoria Utilidade):
 * "Olá, {{1}}! {{2}} atribuiu a você uma tarefa de cuidado de {{3}} no
 *  CareHub Plus: {{4}}, em {{5}}. Você pode assumir?"
 * Botões de resposta rápida: [Aceitar] [Recusar]
 */
export const TASK_ASSIGNED_TEMPLATE = "carehub_tarefa_atribuida";

/**
 * Corpo cadastrado na Meta (categoria Utilidade):
 * "Pedido de ajuda para {{1}} pelo CareHub Plus. {{2}} precisa de apoio
 *  agora com: {{3}}. Você consegue ajudar?"
 * Botões de resposta rápida: [Estou indo] [Não posso]
 */
export const SOS_ALERT_TEMPLATE = "carehub_sos_alerta";

/** Ações possíveis nos botões. A ordem segue a dos botões no template. */
export const ButtonAction = {
  taskAccept: "TASK_ACCEPT",
  taskDecline: "TASK_DECLINE",
  sosAccept: "SOS_ACCEPT",
  sosDecline: "SOS_DECLINE",
} as const;

export type ButtonActionValue = (typeof ButtonAction)[keyof typeof ButtonAction];

export interface ButtonPayload {
  action: ButtonActionValue;
  /** Id da tarefa ou do alerta de SOS. */
  targetId: string;
  /** Membro que recebeu a mensagem (um número pode estar em várias redes). */
  memberId: string;
}

const SEPARATOR = "|";

/** Monta o payload "ACAO|alvo|membro" que volta no webhook. */
export function buildPayload({ action, targetId, memberId }: ButtonPayload): string {
  return [action, targetId, memberId].join(SEPARATOR);
}

/** Lê um payload "ACAO|alvo|membro"; devolve `null` se não for nosso. */
export function parsePayload(payload: string | null | undefined): ButtonPayload | null {
  if (!payload) return null;
  const [action, targetId, memberId, ...rest] = payload.split(SEPARATOR);
  const known = Object.values(ButtonAction) as string[];
  if (rest.length > 0 || !known.includes(action) || !targetId || !memberId) {
    return null;
  }
  return { action: action as ButtonActionValue, targetId, memberId };
}
