/*
 * CareHub Plus — Functions / Cérebro da Cora
 *
 * A Cora inteira, num lugar só, usada pelo app (callable) e pelo WhatsApp.
 * Porta do CoraAssistantRepository: resumo, rotina, tarefas, dicas,
 * proposta e confirmação de tarefa e de assunto. A diferença é que tudo que
 * decide acesso roda aqui: quem é a pessoa, o que ela pode fazer e qual
 * rascunho está aguardando confirmação.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";

import { AccessService } from "../../access/accessService";
import {
  canCreateChat,
  canCreateTask,
  canRequestSos,
  canUseCora,
  Channel,
  Identity,
  principalKey,
  ResolvedAccess,
} from "../../access/types";
import { buildInput, ChatTurn, GeminiError, TextGenerator } from "../../ai/geminiClient";
import { DailyLimiter } from "../../shared/dailyLimiter";
import { db } from "../../shared/firestore";
import { ensureFutureLocalIso, formatLocalDateTime, parseLocalIso } from "../../shared/localTime";
import { localIsoNow } from "../../shared/text";
import { ChatDraft, Session, SessionKey, SessionRepository, TaskDraft } from "../sessionRepository";
import { AssistantReply, QuickReply } from "../types";
import { buildCoraPrompt, buildCoraSchema, CoraCapabilities, CoraContext, parseCareIntent } from "./coraPrompts";

/** Intenções estáveis — as mesmas que o app já usava. */
export const CoraIntents = {
  careRecipientSummary: "cora.care_recipient_summary",
  routine: "cora.routine",
  tasks: "cora.tasks",
  careTips: "cora.care_tips",
  confirmTask: "cora.task.create.confirm",
  cancelTask: "cora.task.create.cancel",
  confirmChat: "cora.chat.create.confirm",
  cancelChat: "cora.chat.create.cancel",
  /** Só no WhatsApp: abre o fluxo de SOS (tratado pelo canal). */
  startSos: "cora.sos.start",
} as const;

const R = {
  careRecipient: { label: "Resumo do assistido", intent: CoraIntents.careRecipientSummary },
  routine: { label: "Rotina do assistido", intent: CoraIntents.routine },
  tasks: { label: "Próximas tarefas", intent: CoraIntents.tasks },
  careTips: { label: "Dicas de cuidado", intent: CoraIntents.careTips },
  confirmTask: { label: "✅ Confirmar tarefa", intent: CoraIntents.confirmTask },
  cancelTask: { label: "Cancelar", intent: CoraIntents.cancelTask },
  confirmChat: { label: "✅ Criar assunto", intent: CoraIntents.confirmChat },
  cancelChat: { label: "Cancelar", intent: CoraIntents.cancelChat },
  sos: { label: "Pedir ajuda", intent: CoraIntents.startSos },
} satisfies Record<string, QuickReply>;

/** Categorias padrão do app — usadas quando o canal não envia as da pessoa. */
export const DEFAULT_CATEGORIES: Record<string, string> = {
  health: "Saúde",
  food: "Alimentação",
  medication: "Medicamento",
  appointment: "Consulta",
  activity: "Atividade",
  other: "Outro",
};

const DEFAULT_TASK_CATEGORY = "other";
const DEFAULT_CHAT_CATEGORY = "health";
const TASK_CONTEXT_LIMIT = 8;
const MAX_MESSAGE_LENGTH = 2000;

const FREQUENCY_LABEL: Record<TaskDraft["frequency"], string> = {
  once: "Única",
  daily: "Diária",
  weekly: "Semanal",
};

export interface CoraRequest {
  identity: Identity;
  careRecipientId: string;
  text: string;
  intent?: string | null;
  channel: Channel;
  sessionId: string;
  /** Categorias da pessoa (o app guarda no aparelho). */
  categories?: Record<string, string>;
}

/** A pessoa não pode falar com a Cora sobre esse assistido. */
export class CoraAccessError extends Error {
  constructor() {
    super("Você não tem acesso a este perfil.");
    this.name = "CoraAccessError";
  }
}

export interface CoraDependencies {
  generator: TextGenerator;
  aiDailyLimit: number;
  access?: AccessService;
  sessions?: SessionRepository;
  limiter?: DailyLimiter;
  now?: () => Date;
}

export class CoraBrain {
  private readonly access: AccessService;
  private readonly sessions: SessionRepository;
  private readonly limiter: DailyLimiter;
  private readonly now: () => Date;

  constructor(private readonly deps: CoraDependencies) {
    this.access = deps.access ?? new AccessService();
    this.sessions = deps.sessions ?? new SessionRepository();
    this.limiter = deps.limiter ?? new DailyLimiter("ai_quota");
    this.now = deps.now ?? (() => new Date());
  }

  /** Confere o acesso no servidor. Lança `CoraAccessError` se não houver. */
  async authorize(identity: Identity, careRecipientId: string, channel: Channel): Promise<ResolvedAccess> {
    const access = await this.access.resolve(identity, careRecipientId);
    if (!access || !canUseCora(access, channel)) throw new CoraAccessError();
    return access;
  }

  async reply(request: CoraRequest): Promise<AssistantReply> {
    const access = await this.authorize(request.identity, request.careRecipientId, request.channel);
    const text = request.text.trim().slice(0, MAX_MESSAGE_LENGTH);
    const key: SessionKey = {
      principalKey: principalKey(request.identity),
      persona: "cora",
      careRecipientId: request.careRecipientId,
      sessionId: request.sessionId,
    };
    const session = await this.sessions.load(key);
    const draftBefore = JSON.stringify(session.draft);

    const reply = await this.decide(request, access, text, session);

    await this.sessions.save(
      key,
      session,
      [
        { role: "user", text },
        { role: "model", text: reply.text },
      ],
      JSON.stringify(session.draft) !== draftBefore,
    );
    return reply;
  }

  private async decide(
    request: CoraRequest,
    access: ResolvedAccess,
    text: string,
    session: Session,
  ): Promise<AssistantReply> {
    const caps: CoraCapabilities = {
      channel: request.channel,
      canCreateTask: canCreateTask(access),
      canCreateChat: canCreateChat(access, request.channel),
      canRequestSos: canRequestSos(access),
    };

    // Confirmar e cancelar não dependem do Gemini e só executam o rascunho
    // guardado no servidor.
    switch (request.intent) {
      case CoraIntents.confirmTask:
        return this.confirmTask(request, access, session);
      case CoraIntents.cancelTask:
        session.draft = null;
        return reply("Tudo bem, não vou registrar essa tarefa. Posso ajudar em algo mais?", [R.tasks, R.careRecipient]);
      case CoraIntents.confirmChat:
        return this.confirmChat(request, access, session);
      case CoraIntents.cancelChat:
        session.draft = null;
        return reply("Tudo bem, não vou abrir esse assunto. Posso ajudar em algo mais?", [R.tasks, R.careRecipient]);
    }

    if (!text) return reply("Pode me contar como posso ajudar?", [R.careRecipient, R.tasks]);

    const allowed = await this.limiter.tryConsume("ai", principalKey(request.identity), this.deps.aiDailyLimit);
    if (!allowed) {
      return {
        text: "Você atingiu o limite de conversas com a Cora por hoje. Volte amanhã — tarefas e SOS continuam funcionando.",
        quickReplies: [],
        quotaExceeded: true,
      };
    }

    try {
      const categories = sanitizeCategories(request.categories);
      const context = await this.fetchContext(request.careRecipientId);
      const raw = await this.deps.generator.generate({
        persona: "cora",
        systemInstruction: buildCoraPrompt(context, categories, caps, localIsoNow(this.now())),
        input: buildInput(text, previousTurns(session.history), "cora"),
        temperature: 0.2,
        responseSchema: buildCoraSchema(Object.keys(categories), caps),
      });
      const intent = parseCareIntent(raw, caps);

      if (intent.kind === "create_task") {
        return this.proposeTask(session, intent, categories);
      }
      if (intent.kind === "create_chat") {
        return this.proposeChat(session, access, intent, categories);
      }

      session.draft = null;
      if (intent.kind === "request_sos") {
        return { text: intent.reply, quickReplies: [R.sos], action: { type: "sos_offer" } };
      }
      return reply(intent.reply, [R.careRecipient, R.tasks, R.careTips]);
    } catch (error) {
      if (error instanceof GeminiError) {
        return reply(`${error.message} Você pode tentar novamente em instantes.`, [R.tasks, R.careRecipient]);
      }
      logger.error("Falha na Cora.", { reason: error instanceof Error ? error.message : String(error) });
      return reply("Não consegui consultar a Cora agora. Tente novamente em instantes.", [R.tasks, R.careRecipient]);
    }
  }

  private proposeTask(
    session: Session,
    intent: ReturnType<typeof parseCareIntent>,
    categories: Record<string, string>,
  ): AssistantReply {
    const parsed = parseLocalIso(intent.taskDateTime);
    if (!intent.taskTitle || !parsed) {
      session.draft = null;
      return reply(
        "Entendi que você quer criar uma tarefa, mas preciso do título e do horário. Pode me dizer o que agendar e para quando?",
        [R.tasks, R.careRecipient],
      );
    }

    // O modelo às vezes devolve uma data no passado: reprojeta para o futuro.
    const draft: TaskDraft = {
      type: "task",
      title: intent.taskTitle,
      scheduledTime: ensureFutureLocalIso(parsed, this.now()),
      frequency: toFrequency(intent.taskFrequency),
      categoryId: resolveCategory(intent.categoryId, categories, DEFAULT_TASK_CATEGORY),
    };
    session.draft = draft;

    // A pergunta é montada aqui, não pelo modelo (que pode afirmar ter criado).
    const frequencyNote = draft.frequency === "once" ? "" : ` (${FREQUENCY_LABEL[draft.frequency].toLowerCase()})`;
    const label = categories[draft.categoryId];
    const categoryNote = label ? ` na categoria ${label}` : "";
    return reply(
      `Quer que eu registre "${draft.title}" para ${formatLocalDateTime(draft.scheduledTime)}${frequencyNote}${categoryNote}?`,
      [R.confirmTask, R.cancelTask],
    );
  }

  private proposeChat(
    session: Session,
    access: ResolvedAccess,
    intent: ReturnType<typeof parseCareIntent>,
    categories: Record<string, string>,
  ): AssistantReply {
    if (!intent.chatTitle) {
      session.draft = null;
      return reply(
        "Entendi que você quer abrir um assunto, mas preciso de um título. Sobre o que será a conversa?",
        [R.tasks, R.careRecipient],
      );
    }

    const draft: ChatDraft = {
      type: "chat",
      title: intent.chatTitle,
      categoryId: resolveCategory(intent.categoryId, categories, DEFAULT_CHAT_CATEGORY),
    };
    session.draft = draft;
    const label = categories[draft.categoryId];
    const categoryNote = label ? ` na categoria ${label}` : "";
    return reply(
      `Quer que eu abra o assunto "${draft.title}" para ${access.careRecipientName || "o assistido"}${categoryNote}?`,
      [R.confirmChat, R.cancelChat],
    );
  }

  private async confirmTask(request: CoraRequest, access: ResolvedAccess, session: Session): Promise<AssistantReply> {
    const draft = session.draft;
    if (draft?.type !== "task") {
      return reply("Não há nenhuma tarefa aguardando confirmação. Quer criar uma nova?", [R.tasks, R.careRecipient]);
    }
    if (!canCreateTask(access)) {
      session.draft = null;
      return reply("Seu nível de acesso não permite criar tarefas para este perfil.", [R.tasks]);
    }

    try {
      const id = `task_${this.now().getTime()}`;
      await db.collection("tasks").doc(id).set({
        id,
        // A tarefa pertence sempre à dona do assistido; `createdBy` diz quem criou.
        caregiverId: access.ownerId,
        careRecipientId: access.careRecipientId,
        title: draft.title,
        description: "",
        scheduledTime: draft.scheduledTime,
        categoryId: draft.categoryId,
        frequency: draft.frequency,
        assignedToName: null,
        assignedToMemberId: null,
        assignedToPhotoUrl: null,
        isCompleted: false,
        completedAt: null,
        completionNote: null,
        createdBy: request.identity.uid ?? principalKey(request.identity),
        createdVia: request.channel === "whatsapp" ? "cora_whatsapp" : "cora_app",
      });
      session.draft = null;
      return reply(
        `✅ Pronto! Registrei "${draft.title}" para ${formatLocalDateTime(draft.scheduledTime)}. Ela aparece na aba Tarefas.`,
        [R.tasks, R.careRecipient],
      );
    } catch (error) {
      logger.error("Falha ao salvar tarefa da Cora.", { reason: error instanceof Error ? error.message : String(error) });
      return reply(
        "Não consegui salvar a tarefa agora. Tente confirmar novamente em instantes ou cadastre pela aba Tarefas.",
        [R.confirmTask, R.cancelTask],
      );
    }
  }

  private async confirmChat(request: CoraRequest, access: ResolvedAccess, session: Session): Promise<AssistantReply> {
    const draft = session.draft;
    if (draft?.type !== "chat") {
      return reply("Não há nenhum assunto aguardando confirmação. Quer criar um novo?", [R.tasks, R.careRecipient]);
    }
    if (!canCreateChat(access, request.channel)) {
      session.draft = null;
      return reply("Assuntos do chat só podem ser abertos pelo app.", [R.tasks]);
    }

    try {
      const id = `room_${this.now().getTime()}`;
      await db.collection("chat_rooms").doc(id).set({
        id,
        title: draft.title,
        lastMessage: "Assunto criado.",
        lastMessageTime: localIsoNow(this.now()),
        unreadCount: 0,
        avatarUrl: null,
        careRecipientName: access.careRecipientName,
        careRecipientId: access.careRecipientId,
        categoryId: draft.categoryId,
        responsibleMemberId: null,
        responsibleMemberName: null,
        responsibleMemberPhotoUrl: null,
      });
      session.draft = null;
      return reply(
        `✅ Pronto! Abri o assunto "${draft.title}" para ${access.careRecipientName || "o assistido"}. Ele aparece na aba Chat.`,
        [R.careRecipient, R.tasks],
      );
    } catch (error) {
      logger.error("Falha ao abrir assunto pela Cora.", { reason: error instanceof Error ? error.message : String(error) });
      return reply(
        "Não consegui abrir o assunto agora. Tente confirmar novamente em instantes ou crie pela aba Chat.",
        [R.confirmChat, R.cancelChat],
      );
    }
  }

  /** Contexto do assistido já autorizado: dados básicos e até 8 tarefas. */
  private async fetchContext(careRecipientId: string): Promise<CoraContext> {
    try {
      const recipient = await db.collection("care_recipients").doc(careRecipientId).get();
      const data = recipient.data();
      if (!data) return { contextAvailable: false };

      const tasks = await db.collection("tasks").where("careRecipientId", "==", careRecipientId).get();
      const summaries = tasks.docs
        .map((doc) => doc.data())
        .sort((left, right) => String(left.scheduledTime ?? "9999").localeCompare(String(right.scheduledTime ?? "9999")))
        .slice(0, TASK_CONTEXT_LIMIT)
        .map(taskSummary)
        .filter(Boolean)
        .join("; ");

      return {
        contextAvailable: true,
        careRecipientName: (data.name as string | undefined) ?? null,
        careRecipientType: ((data.recipientType ?? data.type) as string | undefined) ?? null,
        dateOfBirth: (data.dateOfBirth as string | undefined) ?? null,
        tasks: summaries || "Nenhuma tarefa cadastrada para este perfil.",
      };
    } catch {
      return { contextAvailable: false };
    }
  }
}

function reply(text: string, quickReplies: QuickReply[]): AssistantReply {
  return { text, quickReplies };
}

/** Histórico começa sempre por uma fala da pessoa (como no app). */
function previousTurns(history: ChatTurn[]): ChatTurn[] {
  const turns = [...history];
  while (turns.length > 0 && turns[0].role !== "user") turns.shift();
  return turns;
}

function taskSummary(task: FirebaseFirestore.DocumentData): string {
  const title = typeof task.title === "string" ? task.title.trim() : "";
  if (!title) return "";
  const status = task.isCompleted === true ? "concluída" : "pendente";
  const scheduled = parseLocalIso(task.scheduledTime as string | undefined);
  return scheduled ? `${title} em ${formatLocalDateTime(scheduled)} (${status})` : `${title} (${status})`;
}

function toFrequency(value: string | undefined): TaskDraft["frequency"] {
  return value === "daily" || value === "weekly" ? value : "once";
}

function resolveCategory(suggested: string | undefined, categories: Record<string, string>, fallback: string): string {
  return suggested && categories[suggested] ? suggested : fallback;
}

/** Aceita as categorias enviadas pelo app com limites de tamanho. */
export function sanitizeCategories(input: Record<string, string> | undefined): Record<string, string> {
  if (!input || typeof input !== "object") return { ...DEFAULT_CATEGORIES };
  const entries = Object.entries(input)
    .filter(([id, label]) => /^[\w-]{1,40}$/.test(id) && typeof label === "string" && label.trim() && label.length <= 40)
    .slice(0, 30)
    .map(([id, label]) => [id, label.trim()] as const);
  return entries.length > 0 ? Object.fromEntries(entries) : { ...DEFAULT_CATEGORIES };
}
