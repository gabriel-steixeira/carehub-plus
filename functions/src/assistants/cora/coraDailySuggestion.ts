/*
 * CareHub Plus — Functions / Sugestão diária da Cora
 *
 * Gera UMA sugestão proativa de cuidado por assistido por dia, adaptada ao
 * perfil (idoso, pet, criança...). O resultado é cacheado uma vez por dia no
 * Firestore (care_recipients/{id}/cora/daily_suggestion), então reaberturas
 * do app no mesmo dia devolvem o cache sem chamar o Gemini — no máximo uma
 * chamada por assistido por dia. Espelha o CoraBrain: classe com dependências
 * injetáveis para permitir testes com um dublê do Gemini.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { FieldValue } from "firebase-admin/firestore";

import { APP_TIME_ZONE } from "../../config";
import { AccessService } from "../../access/accessService";
import { canUseCora, Identity, principalKey } from "../../access/types";
import { GeminiError, TextGenerator } from "../../ai/geminiClient";
import { DailyLimiter } from "../../shared/dailyLimiter";
import { db } from "../../shared/firestore";
import { formatLocalDateTime, parseLocalIso } from "../../shared/localTime";
import { CoraAccessError } from "./coraBrain";

const TASK_CONTEXT_LIMIT = 8;
const DEFAULT_CATEGORY = "dica";
const DEFAULT_ACTION_LABEL = "Falar com a Cora";
const MAX_FIELD_LENGTH = 300;

/** Sugestão no formato consumido pelo app (SuggestionModel.fromJson). */
export interface DailySuggestion {
  id: string;
  title: string;
  description: string;
  actionLabel: string;
  category: string;
  iconName: string | null;
}

/** Saída da callable: a sugestão do dia ou `null` quando não há. */
export interface DailySuggestionResult {
  suggestion: DailySuggestion | null;
}

export interface DailySuggestionRequest {
  identity: Identity;
  careRecipientId: string;
}

export interface CoraDailySuggestionDependencies {
  generator: TextGenerator;
  aiDailyLimit: number;
  access?: AccessService;
  limiter?: DailyLimiter;
  now?: () => Date;
}

/** Contexto mínimo do assistido para montar a sugestão. */
interface RecipientContext {
  name: string | null;
  type: string | null;
  dateOfBirth: string | null;
  approximateAge: number | null;
  tasks: string | null;
}

export class CoraDailySuggestion {
  private readonly access: AccessService;
  private readonly limiter: DailyLimiter;
  private readonly now: () => Date;

  constructor(private readonly deps: CoraDailySuggestionDependencies) {
    this.access = deps.access ?? new AccessService();
    this.limiter = deps.limiter ?? new DailyLimiter("ai_quota");
    this.now = deps.now ?? (() => new Date());
  }

  /** Confere o acesso no servidor. Lança `CoraAccessError` se não houver. */
  async authorize(identity: Identity, careRecipientId: string): Promise<void> {
    const access = await this.access.resolve(identity, careRecipientId);
    if (!access || !canUseCora(access, "app")) throw new CoraAccessError();
  }

  async suggest(request: DailySuggestionRequest): Promise<DailySuggestionResult> {
    await this.authorize(request.identity, request.careRecipientId);

    const today = this.localDate();
    const cacheRef = db
      .collection("care_recipients")
      .doc(request.careRecipientId)
      .collection("cora")
      .doc("daily_suggestion");

    // Cache hit: mesma data local → devolve sem tocar no Gemini.
    const cached = await cacheRef.get();
    if (cached.exists && cached.get("date") === today) {
      return { suggestion: (cached.get("suggestion") as DailySuggestion | null) ?? null };
    }

    const cachedSuggestion = (cached.get("suggestion") as DailySuggestion | null) ?? null;

    // Cota de IA só é consumida no cache miss (chamada real ao Gemini).
    const allowed = await this.limiter.tryConsume("ai", principalKey(request.identity), this.deps.aiDailyLimit);
    if (!allowed) {
      // Painel nunca bloqueia: devolve o cache antigo se existir.
      return { suggestion: cachedSuggestion };
    }

    try {
      const context = await this.fetchContext(request.careRecipientId);
      const raw = await this.deps.generator.generate({
        persona: "cora",
        systemInstruction: buildDailyPrompt(context, this.localDateTime()),
        input: buildDailyInput(context),
        temperature: 0.4,
        responseSchema: buildDailySchema(),
      });

      const suggestion = parseDailySuggestion(raw, request.careRecipientId, today);
      await cacheRef.set(
        { date: today, suggestion, createdAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return { suggestion };
    } catch (error) {
      if (error instanceof GeminiError) {
        // Falha temporária do Gemini: devolve o cache antigo em vez de quebrar.
        return { suggestion: cachedSuggestion };
      }
      logger.error("coraDailySuggestion falhou ao gerar.", {
        reason: error instanceof Error ? error.message : String(error),
      });
      return { suggestion: cachedSuggestion };
    }
  }

  /** Data de hoje em Brasília no formato AAAA-MM-DD. */
  private localDate(): string {
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: APP_TIME_ZONE,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(this.now());
  }

  /** Data e hora local "DD/MM/AAAA às HH:MM" para situar o modelo. */
  private localDateTime(): string {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: APP_TIME_ZONE,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    }).formatToParts(this.now());
    const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "00";
    return formatLocalDateTime(
      `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}:00.000`,
    );
  }

  /** Contexto do assistido já autorizado: dados básicos e até 8 tarefas. */
  private async fetchContext(careRecipientId: string): Promise<RecipientContext> {
    try {
      const recipient = await db.collection("care_recipients").doc(careRecipientId).get();
      const data = recipient.data();
      if (!data) return emptyContext();

      const tasks = await db.collection("tasks").where("careRecipientId", "==", careRecipientId).get();
      const summaries = tasks.docs
        .map((doc) => doc.data())
        .sort((left, right) => String(left.scheduledTime ?? "9999").localeCompare(String(right.scheduledTime ?? "9999")))
        .slice(0, TASK_CONTEXT_LIMIT)
        .map(taskSummary)
        .filter(Boolean)
        .join("; ");

      const dateOfBirth = (data.dateOfBirth as string | undefined) ?? null;
      return {
        name: (data.name as string | undefined) ?? null,
        type: ((data.recipientType ?? data.type) as string | undefined) ?? null,
        dateOfBirth,
        approximateAge: approximateAge(dateOfBirth, this.now()),
        tasks: summaries || "Nenhuma tarefa cadastrada para este perfil.",
      };
    } catch {
      return emptyContext();
    }
  }
}

function emptyContext(): RecipientContext {
  return { name: null, type: null, dateOfBirth: null, approximateAge: null, tasks: null };
}

function taskSummary(task: FirebaseFirestore.DocumentData): string {
  const title = typeof task.title === "string" ? task.title.trim() : "";
  if (!title) return "";
  const status = task.isCompleted === true ? "concluída" : "pendente";
  const scheduled = parseLocalIso(task.scheduledTime as string | undefined);
  return scheduled ? `${title} em ${formatLocalDateTime(scheduled)} (${status})` : `${title} (${status})`;
}

/** Idade aproximada em anos a partir da data de nascimento (ISO), se houver. */
function approximateAge(dateOfBirth: string | null, now: Date): number | null {
  if (!dateOfBirth) return null;
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(dateOfBirth.trim());
  if (!match) return null;
  const [, year, month, day] = match;
  const birth = new Date(Date.UTC(+year, +month - 1, +day));
  if (Number.isNaN(birth.getTime())) return null;
  const diff = now.getTime() - birth.getTime();
  if (diff <= 0) return null;
  return Math.floor(diff / (365.25 * 24 * 60 * 60 * 1000));
}

/** Instrução de sistema para UMA sugestão proativa adaptada ao perfil. */
export function buildDailyPrompt(context: RecipientContext, nowLocal: string): string {
  const lines: string[] = [];
  const add = (label: string, value: string | number | null | undefined) => {
    if (value !== null && value !== undefined && String(value).trim()) lines.push(`${label}: ${value}`);
  };
  add("Nome", context.name);
  add("Tipo", context.type);
  add("Idade aproximada", context.approximateAge !== null ? `${context.approximateAge} anos` : null);
  add("Tarefas cadastradas", context.tasks);
  const contextBlock = lines.length === 0 ? "Nenhuma informação do assistido foi disponibilizada." : lines.join("\n");

  return `Você é a Cora, assistente de cuidado e rotina do CareHub Plus.
Gere UMA única sugestão proativa e gentil de cuidado para o assistido abaixo,
pensando no bem-estar diário dele. Responda SEMPRE no formato JSON solicitado.

Como pensar a sugestão:
- adapte ao perfil: idoso → hidratação, alimentação, movimento leve, sono,
  companhia; pet → vacinação, passeio, água fresca, higiene; criança → rotina
  de sono, alimentação, brincadeiras, higiene;
- se não souber o tipo, faça uma sugestão geral e acolhedora de cuidado;
- NÃO repita algo que já esteja nas tarefas cadastradas;
- seja específica e acionável, mas gentil; uma frase de contexto ajuda
  (ex.: "Idosos costumam beber pouca água ao longo do dia.");
- NUNCA diagnostique nem prescreva medicação; não alarme; em emergência,
  oriente procurar ajuda profissional.

Campos do JSON:
- "titulo": chamada curta em português (ex.: "Lembre de oferecer água");
- "descricao": 1 a 2 frases explicando a sugestão, em português;
- "rotulo_acao": texto curto do botão, "Adicionar tarefa" ou "Falar com a Cora";
- "categoria": uma palavra curta em português (hidratação, saúde, rotina, dica).

Data e hora local: ${nowLocal}
Contexto autorizado do assistido:
${contextBlock}
`;
}

/** Mensagem de entrada enviada ao modelo. */
export function buildDailyInput(context: RecipientContext): string {
  const who = context.name ? `o assistido ${context.name}` : "o assistido selecionado";
  return `Gere a sugestão de cuidado de hoje para ${who}.`;
}

/** Schema JSON que casa com SuggestionModel (sem o id, montado no servidor). */
export function buildDailySchema(): Record<string, unknown> {
  return {
    type: "object",
    properties: {
      titulo: { type: "string", description: "Chamada curta da sugestão, em português." },
      descricao: { type: "string", description: "Explicação curta (1 a 2 frases), em português." },
      rotulo_acao: {
        type: "string",
        enum: ["Adicionar tarefa", "Falar com a Cora"],
        description: "Texto do botão de ação.",
      },
      categoria: {
        type: "string",
        description: "Palavra curta em português: hidratação, saúde, rotina ou dica.",
      },
    },
    required: ["titulo", "descricao"],
  };
}

/** Lê o JSON do modelo e monta a sugestão final com id estável. */
export function parseDailySuggestion(
  rawText: string,
  careRecipientId: string,
  today: string,
): DailySuggestion | null {
  let decoded: Record<string, unknown>;
  try {
    decoded = JSON.parse(rawText) as Record<string, unknown>;
  } catch {
    return null;
  }

  const field = (key: string) => {
    const value = decoded[key];
    return typeof value === "string" && value.trim() ? value.trim().slice(0, MAX_FIELD_LENGTH) : null;
  };

  const title = field("titulo");
  const description = field("descricao");
  if (!title || !description) return null;

  return {
    id: `daily_${careRecipientId}_${today}`,
    title,
    description,
    actionLabel: field("rotulo_acao") ?? DEFAULT_ACTION_LABEL,
    category: field("categoria") ?? DEFAULT_CATEGORY,
    iconName: null,
  };
}
