/*
 * CareHub Plus — Testes / Cérebro da Cora, triagem do Toke e cliente Gemini
 *
 * O Gemini é trocado por um dublê que devolve respostas prontas e registra
 * o que recebeu. Assim dá para provar que ações não permitidas nem chegam
 * ao modelo, que a confirmação só executa o rascunho do servidor e que a
 * cota de IA é respeitada — sem gastar cota real.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { clearFirestore } from "./helpers";

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";

import { GrantRepository } from "../../src/access/grantRepository";
import { GeminiClient, GeminiError, GenerateInput, TextGenerator } from "../../src/ai/geminiClient";
import { CoraAccessError, CoraBrain, CoraIntents, CoraRequest } from "../../src/assistants/cora/coraBrain";
import { parseSupportIntent } from "../../src/assistants/toke/tokeInterpreter";
import { db } from "../../src/shared/firestore";
import { ensureFutureLocalIso, formatLocalDateTime, parseLocalIso } from "../../src/shared/localTime";

const OWNER = "alice";

/** Dublê do Gemini: devolve as respostas da fila e guarda as chamadas. */
class FakeGemini implements TextGenerator {
  calls: GenerateInput[] = [];
  constructor(private readonly answers: (string | Error)[] = []) {}
  async generate(input: GenerateInput): Promise<string> {
    this.calls.push(input);
    const next = this.answers.shift() ?? JSON.stringify({ acao: "conversar", resposta: "Ok." });
    if (next instanceof Error) throw next;
    return next;
  }
  actionsOffered(index = 0): string[] {
    const schema = this.calls[index].responseSchema as { properties: { acao: { enum: string[] } } };
    return schema.properties.acao.enum;
  }
}

/** Relógio fixo: 06/10/2026 12:00 em Brasília. */
const NOW = new Date("2026-10-06T15:00:00Z");

function brain(fake: FakeGemini, aiDailyLimit = 60): CoraBrain {
  return new CoraBrain({ generator: fake, aiDailyLimit, now: () => NOW });
}

function request(overrides: Partial<CoraRequest> = {}): CoraRequest {
  return {
    identity: { uid: OWNER, contactKey: null },
    careRecipientId: "r1",
    text: "Oi",
    channel: "app",
    sessionId: "s1",
    ...overrides,
  };
}

async function grant(uidOrKey: { uid?: string; contactKey?: string }, level: string, permissions: string[] = []) {
  const grants = new GrantRepository();
  const pending = await grants.upsertPending({
    careRecipientId: "r1",
    ownerId: OWNER,
    memberId: `m_${uidOrKey.uid ?? uidOrKey.contactKey}`,
    accessLevel: level as "full",
    permissions: permissions as [],
    durationHours: null,
  });
  await grants.activate(pending.id, uidOrKey);
}

beforeEach(async () => {
  await clearFirestore();
  await db.collection("care_recipients").doc("r1").set({ id: "r1", name: "Lúcia", caregiverId: OWNER, type: "person" });
  await db.collection("tasks").doc("t1").set({
    id: "t1",
    caregiverId: OWNER,
    careRecipientId: "r1",
    title: "Remédio de pressão",
    scheduledTime: "2026-10-06T08:00:00.000",
    isCompleted: true,
  });
});

describe("Horário local", () => {
  it("lê com e sem fuso e formata como o app", () => {
    assert.equal(parseLocalIso("2026-10-06T18:00"), "2026-10-06T18:00:00.000");
    assert.equal(parseLocalIso("2026-10-06T21:00:00Z"), "2026-10-06T18:00:00.000");
    assert.equal(parseLocalIso("ontem"), null);
    assert.equal(formatLocalDateTime("2026-10-06T18:05:00.000"), "06/10/2026 às 18:05");
  });

  it("nunca agenda no passado, preservando hora e minuto", () => {
    assert.equal(ensureFutureLocalIso("2026-10-06T18:00:00.000", NOW), "2026-10-06T18:00:00.000");
    assert.equal(ensureFutureLocalIso("2024-01-01T18:00:00.000", NOW), "2026-10-06T18:00:00.000");
    assert.equal(ensureFutureLocalIso("2024-01-01T08:00:00.000", NOW), "2026-10-07T08:00:00.000");
    assert.equal(ensureFutureLocalIso("2026-12-31T08:00:00.000", new Date("2026-12-31T20:00:00Z")), "2027-01-01T08:00:00.000");
  });
});

describe("CoraBrain — app", () => {
  it("propõe tarefa e só cria ao confirmar, no nome da dona", async () => {
    const fake = new FakeGemini([
      JSON.stringify({ acao: "criar_tarefa", resposta: "Criei!", titulo: "Dar ração", data_hora: "2026-10-06T18:00", categoria: "food" }),
    ]);
    const cora = brain(fake);

    const proposal = await cora.reply(request({ text: "lembra de dar ração às 18h" }));
    assert.equal(proposal.text, 'Quer que eu registre "Dar ração" para 06/10/2026 às 18:00 na categoria Alimentação?');
    assert.deepEqual(proposal.quickReplies.map((r) => r.intent), [CoraIntents.confirmTask, CoraIntents.cancelTask]);
    assert.equal((await db.collection("tasks").get()).size, 1);

    const done = await cora.reply(request({ text: "✅ Confirmar tarefa", intent: CoraIntents.confirmTask }));
    assert.match(done.text, /^✅ Pronto! Registrei "Dar ração"/);

    const created = (await db.collection("tasks").where("title", "==", "Dar ração").get()).docs[0].data();
    assert.equal(created.caregiverId, OWNER);
    assert.equal(created.careRecipientId, "r1");
    assert.equal(created.scheduledTime, "2026-10-06T18:00:00.000");
    assert.equal(created.categoryId, "food");
    assert.equal(created.createdBy, OWNER);
    assert.equal(fake.calls.length, 1, "confirmar não chama o Gemini");
  });

  it("confirmar sem rascunho no servidor não cria nada", async () => {
    const reply = await brain(new FakeGemini()).reply(request({ intent: CoraIntents.confirmTask }));
    assert.match(reply.text, /Não há nenhuma tarefa aguardando confirmação/);
    assert.equal((await db.collection("tasks").get()).size, 1);
  });

  it("nova sessão (tela reaberta) descarta o rascunho anterior", async () => {
    const fake = new FakeGemini([
      JSON.stringify({ acao: "criar_tarefa", resposta: "?", titulo: "Banho", data_hora: "2026-10-06T19:00" }),
    ]);
    const cora = brain(fake);
    await cora.reply(request({ text: "banho às 19h" }));
    const reply = await cora.reply(request({ intent: CoraIntents.confirmTask, sessionId: "s2" }));
    assert.match(reply.text, /Não há nenhuma tarefa/);
  });

  it("envia ao modelo o contexto do assistido e o histórico", async () => {
    const fake = new FakeGemini();
    const cora = brain(fake);
    await cora.reply(request({ text: "Primeira" }));
    await cora.reply(request({ text: "Segunda" }));

    assert.match(fake.calls[0].systemInstruction, /Nome: Lúcia/);
    assert.match(fake.calls[0].systemInstruction, /Remédio de pressão em 06\/10\/2026 às 08:00 \(concluída\)/);
    assert.match(fake.calls[1].input, /Cuidador: Primeira\nCora: Ok\./);
  });

  it("estranho não fala com a Cora sobre o assistido", async () => {
    await assert.rejects(
      brain(new FakeGemini()).reply(request({ identity: { uid: "zeca", contactKey: null } })),
      CoraAccessError,
    );
  });

  it("Apenas Visualização conversa no app, mas não recebe a ação de criar", async () => {
    await grant({ uid: "caio" }, "readonly");
    const fake = new FakeGemini([
      JSON.stringify({ acao: "criar_tarefa", resposta: "?", titulo: "X", data_hora: "2026-10-06T18:00" }),
    ]);
    const reply = await brain(fake).reply(request({ identity: { uid: "caio", contactKey: null } }));
    assert.deepEqual(fake.actionsOffered(), ["conversar"]);
    assert.equal(reply.quickReplies.some((r) => r.intent === CoraIntents.confirmTask), false);
  });

  it("cota de IA esgotada não chama o Gemini", async () => {
    const fake = new FakeGemini();
    const cora = brain(fake, 1);
    await cora.reply(request());
    const blocked = await cora.reply(request());
    assert.equal(blocked.quotaExceeded, true);
    assert.equal(fake.calls.length, 1);
  });

  it("erro do Gemini vira a mesma mensagem do app", async () => {
    const reply = await brain(new FakeGemini([new GeminiError("A Cora recebeu muitas solicitações. Aguarde um momento.", 429)])).reply(
      request(),
    );
    assert.equal(reply.text, "A Cora recebeu muitas solicitações. Aguarde um momento. Você pode tentar novamente em instantes.");
  });
});

describe("CoraBrain — WhatsApp", () => {
  const KEY = "5511988887777";

  it("não oferece chat e oferece SOS para quem pode", async () => {
    await grant({ contactKey: KEY }, "full");
    const fake = new FakeGemini([JSON.stringify({ acao: "pedir_sos", resposta: "Posso avisar sua rede." })]);
    const reply = await brain(fake).reply(request({ identity: { uid: null, contactKey: KEY }, channel: "whatsapp" }));

    assert.deepEqual(fake.actionsOffered(), ["conversar", "criar_tarefa", "pedir_sos"]);
    assert.match(fake.calls[0].systemInstruction, /chat da rede de apoio existe só no app/);
    assert.equal(reply.action?.type, "sos_offer");
    assert.deepEqual(reply.quickReplies.map((r) => r.intent), [CoraIntents.startSos]);
  });

  it("modelo insistindo em criar_chat no WhatsApp vira conversa", async () => {
    await grant({ contactKey: KEY }, "full");
    const fake = new FakeGemini([JSON.stringify({ acao: "criar_chat", resposta: "Abro?", titulo_chat: "X" })]);
    const reply = await brain(fake).reply(request({ identity: { uid: null, contactKey: KEY }, channel: "whatsapp" }));
    assert.equal(reply.quickReplies.some((r) => r.intent === CoraIntents.confirmChat), false);
  });

  it("Apenas Visualização e Parcial sem cora não usam o WhatsApp", async () => {
    await grant({ contactKey: KEY }, "readonly");
    await grant({ contactKey: "5511977776666" }, "partial", ["task"]);
    const cora = brain(new FakeGemini());
    await assert.rejects(cora.reply(request({ identity: { uid: null, contactKey: KEY }, channel: "whatsapp" })), CoraAccessError);
    await assert.rejects(
      cora.reply(request({ identity: { uid: null, contactKey: "5511977776666" }, channel: "whatsapp" })),
      CoraAccessError,
    );
  });

  it("Parcial com cora e task cria tarefa, sem SOS", async () => {
    await grant({ contactKey: KEY }, "partial", ["cora", "task"]);
    const fake = new FakeGemini();
    await brain(fake).reply(request({ identity: { uid: null, contactKey: KEY }, channel: "whatsapp" }));
    assert.deepEqual(fake.actionsOffered(), ["conversar", "criar_tarefa"]);
  });
});

describe("Toke", () => {
  it("descarta plano fora do catálogo e ciclo inválido", () => {
    const parsed = parseSupportIntent(
      JSON.stringify({ acao: "contratar_plano", resposta: "Confirma?", plano_id: "hack", ciclo: "weekly" }),
      ["family", "free"],
    );
    assert.equal(parsed.kind, "contract_plan");
    assert.equal(parsed.planId, null);
    assert.equal(parsed.billingCycle, null);
  });

  it("texto sem JSON vira conversa", () => {
    assert.equal(parseSupportIntent("Olá!", []).kind, "conversation");
  });
});

describe("GeminiClient", () => {
  function fakeFetch(responses: { status: number; body: string }[]) {
    const calls: RequestInit[] = [];
    const impl = (async (_url: string, init: RequestInit) => {
      calls.push(init);
      const next = responses.shift() ?? { status: 500, body: "" };
      return new Response(next.body, { status: next.status });
    }) as unknown as typeof fetch;
    return { impl, calls };
  }

  const ok = JSON.stringify({ steps: [{ type: "model_output", content: [{ type: "text", text: "Olá" }] }] });

  it("extrai o texto e repete uma vez em falha temporária", async () => {
    const { impl, calls } = fakeFetch([
      { status: 503, body: "" },
      { status: 200, body: ok },
    ]);
    const client = new GeminiClient({ apiKey: "k", model: "m", fetchImpl: impl, retryDelayMs: 1 });
    assert.equal(await client.generate({ persona: "cora", systemInstruction: "s", input: "i", temperature: 0.2 }), "Olá");
    assert.equal(calls.length, 2);
    assert.equal((calls[0].headers as Record<string, string>)["x-goog-api-key"], "k");
  });

  it("erro definitivo não repete e usa a mensagem da persona", async () => {
    const { impl, calls } = fakeFetch([{ status: 403, body: "" }]);
    const client = new GeminiClient({ apiKey: "k", model: "m", fetchImpl: impl, retryDelayMs: 1 });
    await assert.rejects(
      client.generate({ persona: "toke", systemInstruction: "s", input: "i", temperature: 0.2 }),
      (error: unknown) => error instanceof GeminiError && error.message === "A integração com o Toke não está autorizada.",
    );
    assert.equal(calls.length, 1);
  });

  it("sem chave configurada, avisa sem chamar a API", async () => {
    const { impl, calls } = fakeFetch([]);
    const client = new GeminiClient({ apiKey: " ", model: "m", fetchImpl: impl });
    await assert.rejects(
      client.generate({ persona: "cora", systemInstruction: "s", input: "i", temperature: 0.2 }),
      /A integração com a Cora ainda não foi configurada/,
    );
    assert.equal(calls.length, 0);
  });
});
