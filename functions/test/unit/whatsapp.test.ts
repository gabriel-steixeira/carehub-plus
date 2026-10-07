/*
 * CareHub Plus — Testes / Porteiro e Cora no WhatsApp
 *
 * Simula mensagens chegando pelo webhook (já com assinatura validada) e
 * confere o destino de cada uma: número desconhecido não gera nenhuma
 * chamada ao Gemini nem resposta; convite ativa só com o número certo;
 * Apenas Visualização recebe aviso; escolha de assistido; SOS sem IA;
 * confirmação por SIM; botões da rede continuam funcionando; nada vai
 * para o chat do app.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { clearFirestore } from "./helpers";

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";

import { GrantRepository, grantIdForMember } from "../../src/access/grantRepository";
import { InviteService } from "../../src/access/inviteService";
import { GenerateInput, TextGenerator } from "../../src/ai/geminiClient";
import { CoraBrain } from "../../src/assistants/cora/coraBrain";
import { MemberContact } from "../../src/repositories/careRepository";
import { ConversationContext, QuotaBucket } from "../../src/repositories/messageLogRepository";
import { db } from "../../src/shared/firestore";
import { InboundRouter } from "../../src/webhook/inboundRouter";
import { CoraWhatsAppChannel } from "../../src/whatsapp/coraWhatsAppChannel";
import { SosConversation } from "../../src/whatsapp/sosConversation";
import { InteractiveButton } from "../../src/whatsapp/whatsappClient";
import { Messenger, SendResult, TemplateMessage } from "../../src/whatsapp/whatsappMessenger";

const OWNER = "alice";
const CAREHUB = "5511900001111";
const BIA = "5511988887777";
const OWNER_PHONE = "5511911112222";
const STRANGER = "5511955554444";

interface Sent {
  to: string;
  text: string;
  bucket: QuotaBucket;
  buttons: string[];
}

class FakeMessenger implements Messenger {
  sent: Sent[] = [];
  templates: string[] = [];
  async sendTemplate(_m: MemberContact, _c: ConversationContext, t: TemplateMessage): Promise<SendResult> {
    this.templates.push(t.name);
    return "sent";
  }
  async sendTextInWindow(member: MemberContact, _c: ConversationContext, body: string): Promise<SendResult> {
    this.sent.push({ to: member.phone, text: body, bucket: "network", buttons: [] });
    return "sent";
  }
  async replyInWindow(
    toKey: string,
    _c: ConversationContext,
    body: string,
    options: { bucket: QuotaBucket; quotaKey: string; buttons?: InteractiveButton[] },
  ): Promise<SendResult> {
    this.sent.push({ to: toKey, text: body, bucket: options.bucket, buttons: (options.buttons ?? []).map((b) => b.id) });
    return "sent";
  }
  last(): Sent {
    return this.sent[this.sent.length - 1];
  }
}

class FakeGemini implements TextGenerator {
  calls: GenerateInput[] = [];
  constructor(private readonly answers: string[] = []) {}
  async generate(input: GenerateInput): Promise<string> {
    this.calls.push(input);
    return this.answers.shift() ?? JSON.stringify({ acao: "conversar", resposta: "Resposta da Cora." });
  }
}

interface Harness {
  router: InboundRouter;
  messenger: FakeMessenger;
  gemini: FakeGemini;
  invites: InviteService;
}

function harness(answers: string[] = [], aiDailyLimit = 60): Harness {
  const messenger = new FakeMessenger();
  const gemini = new FakeGemini(answers);
  const invites = new InviteService(CAREHUB, { invitesPerDay: 20, codeAttemptsPerDay: 5 });
  const brain = new CoraBrain({ generator: gemini, aiDailyLimit });
  const cora = new CoraWhatsAppChannel(brain, new SosConversation(5), messenger);
  return { router: new InboundRouter({ messenger, cora, invites }), messenger, gemini, invites };
}

let counter = 0;
async function receive(h: Harness, from: string, text: string, buttonId?: string): Promise<void> {
  counter++;
  await h.router.handleMessage(
    buttonId
      ? { id: `wamid.${counter}`, from, type: "interactive", interactive: { button_reply: { id: buttonId, title: text } } }
      : { id: `wamid.${counter}`, from, type: "text", text: { body: text } },
  );
}

async function seedMember(id: string, recipientId: string, phone: string, extra: Record<string, unknown> = {}) {
  await db.collection("network_members").doc(id).set({
    id,
    name: `Pessoa ${id}`,
    phone,
    caregiverId: OWNER,
    careRecipientId: recipientId,
    accessLevel: "full",
    permissions: [],
    ...extra,
  });
}

/** Convite pelo WhatsApp aceito pelo próprio número do membro. */
async function joinByWhatsApp(h: Harness, memberId: string, phone: string): Promise<void> {
  const invite = await h.invites.createInvite(OWNER, memberId, "whatsapp");
  await receive(h, phone, `ENTRAR ${invite.code}`);
}

beforeEach(async () => {
  await clearFirestore();
  await db.collection("caregivers").doc(OWNER).set({ name: "Alice Souza" });
  await db.collection("care_recipients").doc("r1").set({ id: "r1", name: "Lúcia Maria", caregiverId: OWNER });
  await db.collection("care_recipients").doc("r2").set({ id: "r2", name: "Yuna", caregiverId: OWNER });
  await seedMember("bia_r1", "r1", BIA);
  await seedMember("bia_r2", "r2", BIA);
  await seedMember("vizinho", "r1", "5511933330000");
});

describe("Porteiro", () => {
  it("número desconhecido: zero chamadas ao Gemini e nenhuma resposta", async () => {
    const h = harness();
    await receive(h, STRANGER, "Oi, me passa os remédios da Lúcia?");
    await receive(h, STRANGER, "SOS");
    await receive(h, STRANGER, "ENTRAR"); // sem código: não é comando de entrada
    assert.equal(h.gemini.calls.length, 0);
    assert.equal(h.messenger.sent.length, 0);
  });

  it("texto livre não é guardado no histórico do WhatsApp", async () => {
    const h = harness();
    await receive(h, STRANGER, "dado sensível");
    const stored = (await db.collection("whatsapp_messages").get()).docs[0].data();
    assert.equal(stored.text, null);
    assert.equal(stored.textLength, "dado sensível".length);
  });

  it("convite repassado: outro número recebe recusa e não ganha acesso", async () => {
    const h = harness();
    const invite = await h.invites.createInvite(OWNER, "bia_r1", "whatsapp");
    await receive(h, STRANGER, `ENTRAR ${invite.code}`);
    assert.match(h.messenger.last().text, /Código inválido ou vencido/);

    await receive(h, STRANGER, "Oi");
    assert.equal(h.gemini.calls.length, 0);
  });

  it("convite aceito pelo número certo libera a Cora com botões", async () => {
    const h = harness();
    await joinByWhatsApp(h, "bia_r1", BIA);
    assert.match(h.messenger.last().text, /Agora você acompanha os cuidados de Lúcia/);

    await receive(h, BIA, "Como está a rotina?");
    assert.equal(h.gemini.calls.length, 1);
    assert.equal(h.messenger.last().text, "Resposta da Cora.");
    assert.equal(h.messenger.last().bucket, "cora");
    assert.deepEqual(h.messenger.last().buttons, ["cora.care_recipient_summary", "cora.tasks", "cora.care_tips"]);
  });

  it("Apenas Visualização: aviso no aceite e aviso único se for rebaixado", async () => {
    const h = harness();
    await seedMember("caio", "r1", "5511922221111", { accessLevel: "readonly" });
    const appInvite = await h.invites.createInvite(OWNER, "caio", "app");
    await receive(h, "5511922221111", `ENTRAR ${appInvite.code}`);
    assert.match(h.messenger.last().text, /apenas de visualização e não inclui o WhatsApp/);

    await joinByWhatsApp(h, "bia_r1", BIA);
    await new GrantRepository().updateTerms("bia_r1", { accessLevel: "readonly", permissions: [], durationHours: null });
    const before = h.messenger.sent.length;
    await receive(h, BIA, "Oi");
    await receive(h, BIA, "Oi de novo");
    assert.equal(h.messenger.sent.length, before + 1, "avisa uma vez por dia");
    assert.match(h.messenger.last().text, /apenas de visualização/);
    assert.equal(h.gemini.calls.length, 0);
  });

  it("acesso revogado: o número volta a ser ignorado", async () => {
    const h = harness();
    await joinByWhatsApp(h, "bia_r1", BIA);
    await h.invites.revokeAccess(OWNER, "bia_r1");
    const before = h.messenger.sent.length;
    await receive(h, BIA, "Oi");
    assert.equal(h.gemini.calls.length, 0);
    assert.ok(h.messenger.sent.length <= before + 1);
  });

  it("botões da rede continuam: Estou indo registra o aceite do SOS", async () => {
    const h = harness();
    await db.collection("sos_alerts").doc("sos_1").set({ status: "dispatched", notifiedMemberIds: ["vizinho"] });
    await h.router.handleMessage({
      id: "wamid.btn",
      from: "5511933330000",
      type: "button",
      button: { text: "Estou indo", payload: "SOS_ACCEPT|sos_1|vizinho" },
    });
    const alert = (await db.collection("sos_alerts").doc("sos_1").get()).data() ?? {};
    assert.equal(alert.status, "accepted");
    assert.equal(alert.acceptedByMemberId, "vizinho");
  });

  it("nada que chega pelo WhatsApp vai para o chat do app", async () => {
    const h = harness();
    await db.collection("chat_rooms").doc("c1").set({ careRecipientId: "r1", responsibleMemberId: "vizinho" });
    await receive(h, "5511933330000", "mensagem para o chat");
    assert.equal((await db.collection("chat_rooms").doc("c1").collection("messages").get()).size, 0);
  });
});

describe("Escolha do assistido", () => {
  it("pergunta quando há mais de um, aceita número e nome, e TROCAR", async () => {
    const h = harness();
    await joinByWhatsApp(h, "bia_r1", BIA);
    await joinByWhatsApp(h, "bia_r2", BIA);

    await receive(h, BIA, "Oi");
    assert.match(h.messenger.last().text, /De quem você quer falar\?[\s\S]*1\. Lúcia\n2\. Yuna/);
    assert.equal(h.gemini.calls.length, 0);

    await receive(h, BIA, "2");
    assert.match(h.messenger.last().text, /agora falamos sobre Yuna/);

    await receive(h, BIA, "Tem tarefa hoje?");
    assert.match(h.gemini.calls[0].systemInstruction, /Nome: Yuna/);

    await receive(h, BIA, "falar sobre a Lúcia");
    assert.match(h.messenger.last().text, /agora falamos sobre Lúcia/);

    await receive(h, BIA, "TROCAR");
    assert.match(h.messenger.last().text, /De quem você quer falar/);
  });

  it("a dona liga o próprio número e fala sobre os dois assistidos", async () => {
    const h = harness();
    const self = await h.invites.createSelfLinkCode(OWNER);
    await receive(h, OWNER_PHONE, `ENTRAR ${self.code}`);
    assert.match(h.messenger.last().text, /Seu WhatsApp está ligado à sua conta/);

    await receive(h, OWNER_PHONE, "Oi");
    assert.match(h.messenger.last().text, /1\. Lúcia\n2\. Yuna/);
  });
});

describe("Tarefas pelo WhatsApp", () => {
  it("SIM confirma a tarefa proposta", async () => {
    const h = harness([
      JSON.stringify({ acao: "criar_tarefa", resposta: "?", titulo: "Dar ração", data_hora: "2099-01-01T18:00" }),
    ]);
    await joinByWhatsApp(h, "bia_r1", BIA);
    await receive(h, BIA, "lembra de dar ração às 18h");
    assert.match(h.messenger.last().text, /Quer que eu registre "Dar ração"/);

    await receive(h, BIA, "sim");
    assert.match(h.messenger.last().text, /✅ Pronto! Registrei "Dar ração"/);
    const task = (await db.collection("tasks").get()).docs[0].data();
    assert.equal(task.caregiverId, OWNER);
    assert.equal(task.createdVia, "cora_whatsapp");
    assert.equal(h.gemini.calls.length, 1);
  });
});

describe("SOS pela Cora", () => {
  it("abre sem IA (cota zerada), confirma, avisa a rede sem incluir quem pediu e cancela", async () => {
    const h = harness([], 0);
    await joinByWhatsApp(h, "bia_r1", BIA);

    await receive(h, BIA, "SOS");
    assert.match(h.messenger.last().text, /Vou avisar a rede de apoio de Lúcia/);
    assert.equal(h.messenger.last().bucket, "sos");

    await receive(h, BIA, "Ela caiu no banheiro");
    assert.match(h.messenger.last().text, /Confirma o pedido de ajuda para Lúcia\? Motivo: Ela caiu no banheiro\. Se for uma emergência médica, ligue 192/);

    await receive(h, BIA, "SIM");
    assert.match(h.messenger.last().text, /estou avisando 1 pessoa/);
    assert.equal(h.gemini.calls.length, 0);

    const alerts = await db.collection("sos_alerts").get();
    assert.equal(alerts.size, 1);
    const alert = alerts.docs[0].data();
    assert.equal(alert.status, "dispatched");
    assert.equal(alert.caregiverId, OWNER);
    assert.deepEqual(alert.notifiedMemberIds, ["vizinho"]);
    assert.equal(alert.requestedByName, "Pessoa bia_r1");
    assert.equal(alert.channel, "whatsapp");

    // Um "não" qualquer não derruba o pedido; só CANCELAR.
    await receive(h, BIA, "não");
    assert.equal((await alerts.docs[0].ref.get()).get("status"), "dispatched");
    await receive(h, BIA, "SOS");
    await receive(h, BIA, "CANCELAR");
    assert.equal((await alerts.docs[0].ref.get()).get("status"), "dispatched", "cancelar um novo pedido em andamento não mexe no anterior");
  });

  it("CANCELAR logo após enviar cancela o alerta", async () => {
    const h = harness([], 0);
    await joinByWhatsApp(h, "bia_r1", BIA);
    await receive(h, BIA, "socorro");
    await receive(h, BIA, "Pular");
    await receive(h, BIA, "sim");
    await receive(h, BIA, "CANCELAR");
    const alert = (await db.collection("sos_alerts").get()).docs[0].data();
    assert.equal(alert.status, "cancelled");
  });

  it("Parcial sem SOS recebe recusa e ninguém é avisado", async () => {
    const h = harness();
    await db.collection("network_members").doc("bia_r1").update({ accessLevel: "partial", permissions: ["cora"] });
    await joinByWhatsApp(h, "bia_r1", BIA);
    await db.collection("access_grants").doc(grantIdForMember("bia_r1")).update({ accessLevel: "partial", permissions: ["cora"] });

    await receive(h, BIA, "SOS");
    assert.match(h.messenger.last().text, /não inclui pedir SOS/);
    assert.equal((await db.collection("sos_alerts").get()).size, 0);
  });
});
