/*
 * CareHub Plus — Functions / Escolha do assistido no WhatsApp
 *
 * Quem tem acesso a mais de um assistido precisa dizer de qual quer falar.
 * A comparação é feita aqui, no servidor, contra a lista autorizada — o
 * Gemini nunca decide qual assistido a pessoa pode ver.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { ResolvedAccess } from "../access/types";
import { firstName } from "../shared/text";

/** Minúsculas, sem acento e sem espaços extras. */
export function normalize(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

export function isSwitchCommand(text: string): boolean {
  return /^(trocar|mudar|outro|outra)$/.test(normalize(text));
}

/** "1. Lúcia  2. Yuna" — só os primeiros nomes. */
export function formatChoices(options: ResolvedAccess[]): string {
  return options.map((option, index) => `${index + 1}. ${firstName(option.careRecipientName)}`).join("\n");
}

export function choicesMessage(options: ResolvedAccess[]): string {
  return `De quem você quer falar? Responda com o número ou o nome:\n${formatChoices(options)}`;
}

function matchByName(name: string, options: ResolvedAccess[]): ResolvedAccess | null {
  const wanted = normalize(name).replace(/^(a|o|da|do|de)\s+/, "");
  if (!wanted) return null;
  const hits = options.filter((option) => {
    const full = normalize(option.careRecipientName);
    return full === wanted || normalize(firstName(option.careRecipientName)) === wanted || full.startsWith(`${wanted} `);
  });
  return hits.length === 1 ? hits[0] : null;
}

/** Resposta à lista: "2", "Yuna" ou "a Yuna". */
export function parseChoice(text: string, options: ResolvedAccess[]): ResolvedAccess | null {
  const clean = normalize(text);
  const index = /^\d{1,2}$/.test(clean) ? Number(clean) : NaN;
  if (Number.isInteger(index) && index >= 1 && index <= options.length) return options[index - 1];
  return matchByName(clean, options);
}

/** "falar sobre a Yuna", "mudar para o Rex", "trocar para Lúcia". */
export function parseSwitchRequest(text: string, options: ResolvedAccess[]): ResolvedAccess | null {
  const match = /^(?:quero\s+)?(?:falar|mudar|trocar|conversar)\s+(?:sobre|para|de|com)\s+(.+)$/.exec(normalize(text));
  return match ? matchByName(match[1], options) : null;
}
