/*
 * CareHub Plus — Testes / Convites, espelho e sincronização do membro
 *
 * Cobre criação de convite (canais, nível Apenas Visualização, limite),
 * aceite pelo app (código e e-mail verificado), aceite pelo WhatsApp
 * (número igual ao do membro, aviso de visualização, vínculo da dona),
 * revogação e o espelho que alimenta as regras do Firestore.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { clearFirestore } from "./helpers";

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";

import { Timestamp } from "firebase-admin/firestore";

import { GrantRepository, grantIdForMember } from "../../src/access/grantRepository";
import { mirrorGrant } from "../../src/access/grantMirror";
import {
  generateCode,
  hashCode,
  InviteError,
  InviteService,
  parseEntryCommand,
} from "../../src/access/inviteService";
import { db } from "../../src/shared/firestore";
import { cleanupExpired, syncMemberToGrant } from "../../src/triggers/accessTriggers";

const OWNER = "alice";
const GUEST = "bia";
const CAREHUB = "5511900001111";
const MEMBER_PHONE = "(11) 98888-7777";
const MEMBER_KEY = "5511988887777";

function service(limits = { invitesPerDay: 20, codeAttemptsPerDay: 5 }): InviteService {
  return new InviteService(CAREHUB, limits);
}

async function seed(member: Record<string, unknown> = {}): Promise<void> {
  await db.collection("caregivers").doc(OWNER).set({ name: "Alice Souza" });
  await db.collection("care_recipients").doc("r1").set({ id: "r1", name: "Lúcia Maria", caregiverId: OWNER });
  await db.collection("network_members").doc("m1").set({
    id: "m1",
    name: "Bia Lima",
    phone: MEMBER_PHONE,
    email: "Bia@Example.com",
    caregiverId: OWNER,
    careRecipientId: "r1",
    accessLevel: "full",
    permissions: [],
    accessDurationHours: null,
    ...member,
  });
}

/** O emulador não roda os triggers aqui: o teste aplica o espelho à mão. */
async function mirror(memberId = "m1"): Promise<void> {
  const id = grantIdForMember(memberId);
  const after = (await db.collection("access_grants").doc(id).get()).data();
  await mirrorGrant(id, undefined, after);
}

async function expectInviteError(work: Promise<unknown>, code: string): Promise<void> {
  await assert.rejects(work, (error: unknown) => error instanceof InviteError && error.code === code);
}

beforeEach(async () => {
  await clearFirestore();
});

describe("Código de convite", () => {
  it("tem 6 caracteres sem ambíguos e o hash ignora maiúsculas e espaços", () => {
    for (let i = 0; i < 50; i++) assert.match(generateCode(), /^[2-9A-HJKMNP-Z]{6}$/);
    assert.equal(hashCode("ab3 kq9"), hashCode("AB3KQ9"));
  });

  it("entende a mensagem ENTRAR em formatos comuns", () => {
    assert.equal(parseEntryCommand("ENTRAR 7F3K9Q"), "7F3K9Q");
    assert.equal(parseEntryCommand("  entrar 7f3k9q "), "7F3K9Q");
    assert.equal(parseEntryCommand("Entrar: 7F3K9Q"), "7F3K9Q");
    assert.equal(parseEntryCommand("quero entrar"), null);
    assert.equal(parseEntryCommand("ENTRAR 7F3K"), null);
  });
});

describe("createInvite", () => {
  it("cria concessão pendente, guarda só o hash e devolve texto e link", async () => {
    await seed();
    const invite = await service().createInvite(OWNER, "m1", "whatsapp");

    assert.match(invite.shareText, /Alice convidou você para acompanhar os cuidados de Lúcia/);
    assert.ok(invite.shareText.includes(`https://wa.me/${CAREHUB}?text=ENTRAR%20${invite.code}`));
    assert.ok(invite.shareLink?.startsWith(`https://wa.me/${MEMBER_KEY}?text=`));

    const stored = await db.collection("invites").get();
    assert.equal(stored.size, 1);
    assert.equal(stored.docs[0].get("codeHash"), hashCode(invite.code));
    assert.equal(JSON.stringify(stored.docs[0].data()).includes(invite.code), false);
    assert.equal(stored.docs[0].get("email"), "bia@example.com");

    const grant = await new GrantRepository().getByMember("m1");
    assert.equal(grant?.status, "pending");
  });

  it("pelo app, o texto traz o código e o caminho da tela", async () => {
    await seed();
    const invite = await service().createInvite(OWNER, "m1", "app");
    assert.match(invite.shareText, /Tenho um convite/);
    assert.ok(invite.shareText.includes(invite.code));
  });

  it("recusa WhatsApp para Apenas Visualização e para telefone inválido", async () => {
    await seed({ accessLevel: "readonly" });
    await expectInviteError(service().createInvite(OWNER, "m1", "whatsapp"), "failed-precondition");
    await service().createInvite(OWNER, "m1", "app");

    await db.collection("network_members").doc("m1").update({ accessLevel: "full", phone: "123" });
    await expectInviteError(service().createInvite(OWNER, "m1", "whatsapp"), "invalid-argument");
  });

  it("só a dona do membro convida, e há limite diário", async () => {
    await seed();
    await expectInviteError(service().createInvite("zeca", "m1", "app"), "not-found");

    const limited = service({ invitesPerDay: 1, codeAttemptsPerDay: 5 });
    await limited.createInvite(OWNER, "m1", "app");
    await expectInviteError(limited.createInvite(OWNER, "m1", "app"), "resource-exhausted");
  });

  it("reenviar invalida o código anterior", async () => {
    await seed();
    const first = await service().createInvite(OWNER, "m1", "app");
    await service().createInvite(OWNER, "m1", "app");
    await expectInviteError(service().redeemCode(GUEST, first.code), "not-found");
  });
});

describe("Aceite pelo app", () => {
  it("código válido ativa para a conta logada e só vale uma vez", async () => {
    await seed({ accessDurationHours: 24 });
    const invite = await service().createInvite(OWNER, "m1", "app");

    const redeemed = await service().redeemCode(GUEST, invite.code.toLowerCase());
    assert.deepEqual(redeemed, { careRecipientId: "r1", careRecipientName: "Lúcia Maria" });

    const grant = await new GrantRepository().getByMember("m1");
    assert.equal(grant?.status, "active");
    assert.equal(grant?.principalUid, GUEST);
    assert.ok(grant?.expiresAt);

    await expectInviteError(service().redeemCode("outra", invite.code), "not-found");
  });

  it("código vencido, inexistente ou da própria dona é recusado", async () => {
    await seed();
    const invite = await service().createInvite(OWNER, "m1", "app");
    await expectInviteError(service().redeemCode(OWNER, invite.code), "failed-precondition");
    await expectInviteError(service().redeemCode(GUEST, "ZZZZZZ"), "not-found");

    const stored = await db.collection("invites").get();
    await stored.docs[0].ref.update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    await expectInviteError(service().redeemCode(GUEST, invite.code), "not-found");
  });

  it("limita tentativas de código por conta", async () => {
    await seed();
    const limited = service({ invitesPerDay: 20, codeAttemptsPerDay: 2 });
    await expectInviteError(limited.redeemCode(GUEST, "AAAAAA"), "not-found");
    await expectInviteError(limited.redeemCode(GUEST, "BBBBBB"), "not-found");
    await expectInviteError(limited.redeemCode(GUEST, "CCCCCC"), "resource-exhausted");
  });

  it("e-mail verificado vincula sozinho; sem verificação, não", async () => {
    await seed();
    await service().createInvite(OWNER, "m1", "app");

    assert.deepEqual(await service().claimByVerifiedEmail(GUEST, "bia@example.com", false), []);
    assert.deepEqual(await service().claimByVerifiedEmail(GUEST, "outra@example.com", true), []);

    const claimed = await service().claimByVerifiedEmail(GUEST, "BIA@example.com", true);
    assert.equal(claimed.length, 1);
    assert.equal((await new GrantRepository().getByMember("m1"))?.principalUid, GUEST);
  });
});

describe("Aceite pelo WhatsApp", () => {
  it("ativa só se o número que enviou for o do membro", async () => {
    await seed();
    const invite = await service().createInvite(OWNER, "m1", "whatsapp");

    assert.deepEqual(await service().acceptByWhatsApp(invite.code, "5511977776666"), { kind: "invalid" });
    assert.deepEqual(await service().acceptByWhatsApp(invite.code, MEMBER_KEY), {
      kind: "accepted",
      recipientFirstName: "Lúcia",
    });

    const grant = await new GrantRepository().getByMember("m1");
    assert.equal(grant?.principalContactKey, MEMBER_KEY);
    assert.ok((await db.collection("whatsapp_participants").doc(MEMBER_KEY).get()).exists);
  });

  it("Apenas Visualização recebe aviso e o código continua valendo no app", async () => {
    await seed();
    const invite = await service().createInvite(OWNER, "m1", "app");
    await db.collection("access_grants").doc(grantIdForMember("m1")).update({ accessLevel: "readonly" });

    assert.deepEqual(await service().acceptByWhatsApp(invite.code, MEMBER_KEY), {
      kind: "readonly",
      recipientFirstName: "Lúcia",
    });
    assert.equal((await new GrantRepository().getByMember("m1"))?.status, "pending");
    await service().redeemCode(GUEST, invite.code);
    assert.equal((await new GrantRepository().getByMember("m1"))?.status, "active");
  });

  it("código da dona liga o número dela, um número por conta", async () => {
    await seed();
    const first = await service().createSelfLinkCode(OWNER);
    assert.ok(first.link.startsWith(`https://wa.me/${CAREHUB}?text=ENTRAR%20`));
    assert.deepEqual(await service().acceptByWhatsApp(first.code, "5511911112222"), { kind: "self_linked" });

    const second = await service().createSelfLinkCode(OWNER);
    await service().acceptByWhatsApp(second.code, "5511933334444");

    const links = await db.collection("owner_whatsapp_links").get();
    assert.deepEqual(links.docs.map((doc) => doc.id), ["5511933334444"]);
    assert.equal(links.docs[0].get("uid"), OWNER);
  });

  it("limita tentativas por número", async () => {
    await seed();
    const limited = service({ invitesPerDay: 20, codeAttemptsPerDay: 1 });
    assert.deepEqual(await limited.acceptByWhatsApp("AAAAAA", MEMBER_KEY), { kind: "invalid" });
    assert.deepEqual(await limited.acceptByWhatsApp("AAAAAA", MEMBER_KEY), { kind: "rate_limited" });
  });
});

describe("Revogação, espelho e sincronização", () => {
  it("espelho libera a conta no assistido e a revogação tira na hora", async () => {
    await seed({ accessLevel: "partial", permissions: ["task", "cora"] });
    const invite = await service().createInvite(OWNER, "m1", "app");
    await service().redeemCode(GUEST, invite.code);
    await mirror();

    let recipient = (await db.collection("care_recipients").doc("r1").get()).data() ?? {};
    assert.deepEqual(recipient.accessUids, [GUEST]);
    assert.equal(recipient.access[GUEST].level, "partial");
    assert.deepEqual(recipient.access[GUEST].permissions, ["task", "cora"]);
    assert.equal((await db.collection("network_members").doc("m1").get()).get("inviteStatus"), "active");

    await service().revokeAccess(OWNER, "m1");
    await mirror();
    recipient = (await db.collection("care_recipients").doc("r1").get()).data() ?? {};
    assert.deepEqual(recipient.accessUids, []);
    assert.equal(recipient.access[GUEST], undefined);
    assert.equal((await db.collection("network_members").doc("m1").get()).get("inviteStatus"), "revoked");
  });

  it("só a dona revoga ou cancela", async () => {
    await seed();
    await service().createInvite(OWNER, "m1", "app");
    await expectInviteError(service().revokeAccess("zeca", "m1"), "not-found");
    await expectInviteError(service().cancelInvite("zeca", "m1"), "not-found");
    await service().cancelInvite(OWNER, "m1");
    assert.equal((await new GrantRepository().getByMember("m1"))?.status, "revoked");
  });

  it("editar o membro atualiza a concessão; remover o membro revoga", async () => {
    await seed();
    const invite = await service().createInvite(OWNER, "m1", "app");
    await service().redeemCode(GUEST, invite.code);

    const before = (await db.collection("network_members").doc("m1").get()).data();
    const after = { ...before, accessLevel: "readonly" };
    await syncMemberToGrant("m1", before, after);
    assert.equal((await new GrantRepository().getByMember("m1"))?.accessLevel, "readonly");

    await syncMemberToGrant("m1", after, undefined);
    assert.equal((await new GrantRepository().getByMember("m1"))?.status, "revoked");
  });

  it("limpeza marca vencidos e o espelho tira a conta", async () => {
    await seed({ accessDurationHours: 1 });
    const invite = await service().createInvite(OWNER, "m1", "app");
    await service().redeemCode(GUEST, invite.code);
    await mirror();

    await db
      .collection("access_grants")
      .doc(grantIdForMember("m1"))
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    assert.equal(await cleanupExpired(), 1);
    await mirror();

    const recipient = (await db.collection("care_recipients").doc("r1").get()).data() ?? {};
    assert.deepEqual(recipient.accessUids, []);
    assert.equal((await db.collection("network_members").doc("m1").get()).get("inviteStatus"), "expired");
  });
});
