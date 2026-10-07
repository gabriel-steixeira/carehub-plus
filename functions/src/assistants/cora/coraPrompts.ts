/*
 * CareHub Plus — Functions / Prompts da Cora
 *
 * Instruções, schema JSON e leitura da resposta estruturada da Cora — o
 * mesmo texto que o app usava, agora num lugar só. O que varia por canal e
 * por permissão é decidido aqui pelo servidor: ações não permitidas nem
 * aparecem no schema, então o modelo não consegue propô-las.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { Channel } from "../../access/types";

export interface CoraCapabilities {
  channel: Channel;
  canCreateTask: boolean;
  canCreateChat: boolean;
  canRequestSos: boolean;
}

export interface CoraContext {
  contextAvailable: boolean;
  careRecipientName?: string | null;
  careRecipientType?: string | null;
  dateOfBirth?: string | null;
  tasks?: string | null;
}

export type CareIntentKind = "conversation" | "create_task" | "create_chat" | "request_sos";

export interface CareIntent {
  kind: CareIntentKind;
  reply: string;
  taskTitle?: string;
  taskDateTime?: string;
  taskFrequency?: string;
  chatTitle?: string;
  categoryId?: string;
}

const ACTION_BY_NAME: Record<string, CareIntentKind> = {
  conversar: "conversation",
  criar_tarefa: "create_task",
  criar_chat: "create_chat",
  pedir_sos: "request_sos",
};

function allowedActions(caps: CoraCapabilities): string[] {
  return [
    "conversar",
    ...(caps.canCreateTask ? ["criar_tarefa"] : []),
    ...(caps.canCreateChat ? ["criar_chat"] : []),
    ...(caps.canRequestSos && caps.channel === "whatsapp" ? ["pedir_sos"] : []),
  ];
}

function formatContext(context: CoraContext): string {
  if (!context.contextAvailable) return "Os dados cadastrados não puderam ser consultados agora.";
  const lines: string[] = [];
  const add = (label: string, value: string | null | undefined) => {
    if (value && value.trim()) lines.push(`${label}: ${value}`);
  };
  add("Nome", context.careRecipientName);
  add("Tipo", context.careRecipientType);
  add("Data de nascimento", context.dateOfBirth);
  add("Tarefas cadastradas", context.tasks);
  return lines.length === 0 ? "Nenhuma informação do assistido foi disponibilizada." : lines.join("\n");
}

export function buildCoraPrompt(
  context: CoraContext,
  categories: Record<string, string>,
  caps: CoraCapabilities,
  nowLocalIso: string,
): string {
  const entries = Object.entries(categories);
  const categoriesBlock =
    entries.length === 0
      ? 'Nenhuma categoria disponível; deixe "categoria" vazio.'
      : entries.map(([id, label]) => `- ${id}: ${label}`).join("\n");

  const decide: string[] = [];
  if (caps.canCreateTask) {
    decide.push(
      '- use "criar_tarefa" quando o cuidador pedir para agendar, lembrar, marcar ou\n' +
        '  cadastrar algo com horário (ex.: "cria um lembrete", "marca a consulta");',
    );
  }
  if (caps.canCreateChat) {
    decide.push(
      '- use "criar_chat" quando pedir para abrir um assunto, conversa ou tópico com a\n' +
        '  rede de apoio (ex.: "abre um assunto sobre a consulta", "cria uma conversa\n' +
        '  sobre a medicação");',
    );
  }
  if (caps.canRequestSos && caps.channel === "whatsapp") {
    decide.push(
      '- use "pedir_sos" quando o cuidador relatar uma emergência ou pedir ajuda\n' +
        "  urgente da rede de apoio agora (queda, mal-estar, sumiço, acidente);",
    );
  }
  decide.push('- em qualquer outro caso use "conversar".');

  const limits: string[] = [];
  if (!caps.canCreateTask) {
    limits.push(
      "- esta pessoa tem acesso só para consultar: se ela pedir para criar tarefa,\n" +
        "  explique com gentileza que o nível de acesso dela não permite criar.",
    );
  }
  if (caps.channel === "whatsapp") {
    limits.push(
      "- você está no WhatsApp: o chat da rede de apoio existe só no app. Se pedirem\n" +
        "  para abrir, ler ou responder um assunto do chat, oriente a usar o app;\n" +
        "- responda em mensagens curtas, sem markdown.",
    );
  }

  const taskRules = caps.canCreateTask
    ? `
Regras para "criar_tarefa":
- "titulo": curto e claro, em português (ex.: "Dar ração", "Remédio de pressão");
- "data_hora": ISO 8601 no fuso local; se o cuidador não indicar o dia, use hoje;
  se não indicar hora, use 09:00; nunca invente datas passadas;
- "frequencia": "once" (padrão), "daily" ou "weekly";
- "resposta": NUNCA diga que a tarefa foi criada, registrada ou salva. Apenas
  resuma o que será agendado e pergunte se pode registrar. Exemplo:
  "Quer que eu registre 'Dar ração' hoje às 18:00?".
`
    : "";

  const chatRules = caps.canCreateChat
    ? `
Regras para "criar_chat":
- "titulo_chat": curto e claro, em português (ex.: "Consulta cardiologista",
  "Troca de medicação");
- "resposta": NUNCA diga que o assunto foi criado ou aberto. Apenas resuma e
  pergunte se pode abrir. Exemplo: "Quer que eu abra o assunto 'Consulta'?".
`
    : "";

  const sosRules =
    caps.canRequestSos && caps.channel === "whatsapp"
      ? `
Regras para "pedir_sos":
- "resposta": acolha em uma frase e diga que você pode avisar a rede de apoio;
  NUNCA diga que já avisou alguém; lembre que em emergência médica deve-se
  ligar 192 (SAMU).
`
      : "";

  return `Você é a Cora, assistente de cuidado e rotina do CareHub Plus.
Analise a mensagem do cuidador e responda SEMPRE no formato JSON solicitado.

Como decidir a ação:
${decide.join("\n")}
${taskRules}${chatRules}${sosRules}
Regra de categoria (para criar_tarefa e criar_chat):
- Preencha "categoria" com o id da categoria que melhor descreve o item,
  escolhendo APENAS entre as categorias disponíveis abaixo.
- Se nenhuma encaixar bem, use "other".

Categorias disponíveis (id: rótulo):
${categoriesBlock}

Regras para "conversar":
- responda em português, com acolhimento e objetividade;
- baseie-se somente no contexto; se o dado não existir, diga que não está
  disponível; não diagnostique nem prescreva; em emergência, oriente o SOS.
${limits.length > 0 ? `\nLimites deste atendimento:\n${limits.join("\n")}\n` : ""}
Data e hora local: ${nowLocalIso}
Contexto autorizado do assistido selecionado:
${formatContext(context)}
`;
}

export function buildCoraSchema(categoryIds: string[], caps: CoraCapabilities): Record<string, unknown> {
  const properties: Record<string, unknown> = {
    acao: {
      type: "string",
      enum: allowedActions(caps),
      description:
        "Use criar_tarefa quando o cuidador pedir para agendar, lembrar ou cadastrar algo " +
        "com horário. Use criar_chat quando pedir para abrir um assunto com a rede de apoio. " +
        "Use pedir_sos em emergência. Caso contrário, use conversar.",
    },
    resposta: {
      type: "string",
      description:
        "Mensagem em português para o cuidador. Se acao for criar_tarefa ou criar_chat, " +
        "peça confirmação resumindo.",
    },
    categoria: {
      type: "string",
      ...(categoryIds.length > 0 ? { enum: categoryIds } : {}),
      description:
        "Id da categoria que melhor descreve a tarefa ou o assunto. Escolha entre as " +
        "categorias disponíveis no prompt.",
    },
  };

  if (caps.canCreateTask) {
    properties.titulo = { type: "string", description: "Título curto da tarefa, quando acao for criar_tarefa." };
    properties.data_hora = {
      type: "string",
      description: "Data e hora da tarefa em ISO 8601 no fuso local, quando acao for criar_tarefa.",
    };
    properties.frequencia = {
      type: "string",
      enum: ["once", "daily", "weekly"],
      description: "Recorrência da tarefa, quando acao for criar_tarefa.",
    };
  }
  if (caps.canCreateChat) {
    properties.titulo_chat = { type: "string", description: "Título curto do assunto, quando acao for criar_chat." };
  }

  return { type: "object", properties, required: ["acao", "resposta"] };
}

/** Lê o JSON do modelo. Ação fora das permitidas vira conversa. */
export function parseCareIntent(rawText: string, caps: CoraCapabilities): CareIntent {
  let decoded: Record<string, unknown>;
  try {
    decoded = JSON.parse(rawText) as Record<string, unknown>;
  } catch {
    return { kind: "conversation", reply: rawText.trim() };
  }

  const field = (key: string) => {
    const value = decoded[key];
    return typeof value === "string" && value.trim() ? value.trim() : undefined;
  };
  const action = field("acao") ?? "conversar";
  const kind = allowedActions(caps).includes(action) ? ACTION_BY_NAME[action] : "conversation";
  const reply = field("resposta");

  switch (kind) {
    case "create_task":
      return {
        kind,
        reply: reply ?? "Quer que eu registre essa tarefa?",
        taskTitle: field("titulo"),
        taskDateTime: field("data_hora"),
        taskFrequency: field("frequencia"),
        categoryId: field("categoria"),
      };
    case "create_chat":
      return {
        kind,
        reply: reply ?? "Quer que eu abra esse assunto?",
        chatTitle: field("titulo_chat"),
        categoryId: field("categoria"),
      };
    case "request_sos":
      return { kind, reply: reply ?? "Posso avisar a sua rede de apoio agora." };
    default:
      return { kind: "conversation", reply: reply ?? "Desculpe, não consegui entender. Pode reformular?" };
  }
}
