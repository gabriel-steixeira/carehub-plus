/*
 * CareHub Plus — Functions / Triagem do Toke
 *
 * Só a parte do Toke que precisa do Gemini: interpretar a mensagem e
 * devolver a ação ("No Wrong Door"). As regras da conta — catálogo, preço,
 * contratação após confirmação — continuam no app, que já grava o contrato
 * com as regras do Firestore. Assim a chave do Gemini sai do app sem
 * reescrever o fluxo de assinaturas.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { buildInput, ChatTurn, TextGenerator } from "../../ai/geminiClient";
import { localIsoNow } from "../../shared/text";

export type SupportIntentKind = "conversation" | "simulate_plan" | "contract_plan" | "payment" | "human_handoff";

export interface SupportIntent {
  kind: SupportIntentKind;
  reply: string;
  planId: string | null;
  billingCycle: string | null;
  paymentType: string | null;
  summary: string | null;
}

/** Context Token montado pelo app (só dados da própria conta). */
export interface SupportContext {
  contextAvailable: boolean;
  userName?: string | null;
  currentPlan?: string | null;
  subscription?: string | null;
  pendencies?: string | null;
  catalog?: string | null;
}

const KIND_BY_ACTION: Record<string, SupportIntentKind> = {
  simular_plano: "simulate_plan",
  contratar_plano: "contract_plan",
  pagamento: "payment",
  transferir_humano: "human_handoff",
};

function tokeIdentity(now: string): string {
  return `Você é o Toke Concierge, central de atendimento e suporte do CareHub Plus.
Converse em português do Brasil de forma cordial, profissional e objetiva.

Seu papel (Customer Success):
- atender sem repetição: use o contexto da conta abaixo e nunca peça ao
  cuidador dados que já estão nele;
- se houver pendência no contexto, comece pelo diagnóstico e pela solução;
- orientar navegação, conta, planos e assinatura;
- fazer a triagem: resolver no chat, acionar uma ação do app ou encaminhar a um
  atendente humano com o caso resumido.

Mapa do aplicativo:
- barra inferior: Início, Tarefas, Cora (assistente de cuidado), Chat e SOS;
- Configurações: Rede de Apoio, Notificações, Fale conosco (Toke), Preferências
  (em breve), Planos e Sobre;
- Perfil: editar nome, telefone, data de nascimento e foto;
- dúvidas de cuidado, rotina, remédios ou tarefas são com a Cora; em emergência,
  oriente o botão SOS.

Limites obrigatórios:
- nunca invente preço, plano, cobrança, fatura, prazo ou status da conta; use
  somente o contexto; se o dado não existir, diga que não está disponível;
- o app ainda não tem gateway de pagamento: você não gera Pix, boleto ou
  fatura e não altera cartão;
- nunca afirme que executou uma ação; quem executa é o app, após confirmação;
- nunca peça senha, número completo de cartão ou código de segurança;
- respostas simples devem ter de duas a quatro frases.

Data e hora local: ${now}`;
}

function formatSupportContext(context: SupportContext): string {
  if (!context.contextAvailable) return "Os dados da conta não puderam ser consultados agora.";
  const lines: string[] = [];
  const add = (label: string, value: string | null | undefined) => {
    if (value && value.trim()) lines.push(`${label}: ${value}`);
  };
  add("Cuidador", context.userName);
  add("Plano atual", context.currentPlan);
  add("Contrato", context.subscription);
  add("Pendências detectadas", context.pendencies);
  add("Catálogo de planos (id | nome | mensal | anual | benefícios)", context.catalog);
  return lines.length === 0 ? "Nenhuma informação da conta foi disponibilizada." : lines.join("\n");
}

export function buildTokePrompt(context: SupportContext, now: string): string {
  return `${tokeIdentity(now)}

Analise a mensagem do cuidador e responda SEMPRE no formato JSON solicitado.

Como decidir a ação:
- "simular_plano": quer saber preço, comparar planos ou quanto economiza no
  anual. Preencha "plano_id" com um id do catálogo e "ciclo" se ele indicar;
- "contratar_plano": pede para assinar, trocar ou fazer upgrade de plano.
  Preencha "plano_id" e "ciclo" (use "monthly" se ele não disser). Em
  "resposta", NUNCA diga que contratou: apenas resuma e peça confirmação;
- "pagamento": pede Pix, boleto, segunda via, fatura, trocar cartão ou relata
  cobrança recusada. Preencha "tipo_pagamento" e "resumo";
- "transferir_humano": pede falar com uma pessoa, está insatisfeito ou o
  problema não se resolve pelo app. Preencha "resumo";
- em qualquer outro caso use "conversar".

Contexto da conta (Context Token):
${formatSupportContext(context)}
`;
}

export function buildTokeSchema(planIds: string[]): Record<string, unknown> {
  return {
    type: "object",
    properties: {
      acao: {
        type: "string",
        enum: ["conversar", "simular_plano", "contratar_plano", "pagamento", "transferir_humano"],
        description:
          "simular_plano: quer saber quanto custa ou comparar um plano. contratar_plano: pede " +
          "para assinar, trocar ou fazer upgrade. pagamento: Pix, boleto, fatura, cartão ou " +
          "cobrança recusada. transferir_humano: pede falar com uma pessoa ou o problema não " +
          "pode ser resolvido pelo app. Senão, conversar.",
      },
      resposta: { type: "string", description: "Mensagem em português para o cuidador." },
      plano_id: {
        type: "string",
        ...(planIds.length > 0 ? { enum: planIds } : {}),
        description: "Id do plano do catálogo, para simular_plano ou contratar_plano.",
      },
      ciclo: { type: "string", enum: ["monthly", "annual"], description: "Ciclo de cobrança, se o cuidador indicar." },
      tipo_pagamento: {
        type: "string",
        enum: ["pix", "fatura", "cartao"],
        description: "Tipo do pedido, quando acao for pagamento.",
      },
      resumo: {
        type: "string",
        description: "Resumo objetivo do problema em uma frase, quando acao for transferir_humano ou pagamento.",
      },
    },
    required: ["acao", "resposta"],
  };
}

export function parseSupportIntent(rawText: string, planIds: string[]): SupportIntent {
  let decoded: Record<string, unknown>;
  try {
    decoded = JSON.parse(rawText) as Record<string, unknown>;
  } catch {
    return { kind: "conversation", reply: rawText.trim(), planId: null, billingCycle: null, paymentType: null, summary: null };
  }
  const field = (key: string) => {
    const value = decoded[key];
    return typeof value === "string" && value.trim() ? value.trim() : null;
  };
  const planId = field("plano_id");
  const cycle = field("ciclo");
  const payment = field("tipo_pagamento");
  return {
    kind: KIND_BY_ACTION[field("acao") ?? ""] ?? "conversation",
    reply: field("resposta") ?? "Desculpe, não consegui entender. Pode reformular?",
    planId: planId && (planIds.length === 0 || planIds.includes(planId)) ? planId : null,
    billingCycle: cycle === "monthly" || cycle === "annual" ? cycle : null,
    paymentType: payment === "pix" || payment === "fatura" || payment === "cartao" ? payment : null,
    summary: field("resumo"),
  };
}

export interface TokeRequest {
  text: string;
  history: ChatTurn[];
  context: SupportContext;
  planIds: string[];
}

export class TokeInterpreter {
  constructor(
    private readonly generator: TextGenerator,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async interpret(request: TokeRequest): Promise<SupportIntent> {
    const raw = await this.generator.generate({
      persona: "toke",
      systemInstruction: buildTokePrompt(request.context, localIsoNow(this.now())),
      input: buildInput(request.text, request.history, "toke"),
      temperature: 0.2,
      responseSchema: buildTokeSchema(request.planIds),
    });
    return parseSupportIntent(raw, request.planIds);
  }
}
