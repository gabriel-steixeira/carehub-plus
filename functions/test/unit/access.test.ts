/*
 * CareHub Plus — Testes / Concessões e decisão de acesso
 *
 * Cobre o ciclo da concessão (pendente → ativa → revogada), o prazo contado
 * a partir do aceite, a recusa de tomar uma concessão de outra conta e a
 * decisão de acesso por dono, convidado e canal.
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

import { AccessService } from "../../src/access/accessService";
import { GrantRepository, grantIdForMember } from "../../src/access/grantRepository";
import {
  canCreateChat,
  canCreateTask,
  canRequestSos,
  canUseCora,
  ResolvedAccess,
} from "../../src/access/types";
import { DailyLimiter } from "../../src/shared/dailyLimiter";
import { db } from "../../src/shared/firestore";

const OWNER = "alice";
const GUEST = "bia";
const KEY = "5511988887777";

async function seedRecipient(id: string, name: string, ownerId = OWNER): Promise<void> {
  await db.collection("care_recipients").doc(id).set({ id, name, caregiverId: ownerId });
}

function terms(memberId: string, overrides: Record<string, unknown> = {}) {
  return {
    careRecipientId: "r1",
    ownerId: OWNER,
    memberId,
    accessLevel: "full" as const,
    permissions: [],
    durationHours: null,
    ...overrides,
  };
}

function access(overrides: Partial<ResolvedAccess>): ResolvedAccess {
  return {
    careRecipientId: "r1",
    careRecipientName: "Lúcia",
    ownerId: OWNER,
    role: "grantee",
    level: "full",
    permissions: [],
    grantId: "g",
    ...overrides,
  };
}

beforeEach(async () => {
  await clearFirestore();
  await seedRecipient("r1", "Lúcia");
  await seedRecipient("r2", "Yuna");
});

describe("GrantRepository", () => {
  it("nasce pendente e ativa no aceite, com prazo contado a partir dele", async () => {
    const grants = new GrantRepository();
    const pending = await grants.upsertPending(terms("m1", { durationHours: 2 }));
    assert.equal(pending.status, "pending");
    assert.equal(pending.expiresAt, null);

    const before = Date.now();
    assert.equal(await grants.activate(pending.id, { uid: GUEST }), "activated");
    const active = await grants.get(pending.id);
    assert.equal(active?.status, "active");
    assert.equal(active?.principalUid, GUEST);
    const expires = active?.expiresAt?.toMillis() ?? 0;
    assert.ok(expires >= before + 2 * 3600_000 - 1000 && expires <= Date.now() + 2 * 3600_000);
  });

  it("ilimitado não tem data de expiração", async () => {
    const grants = new GrantRepository();
    const pending = await grants.upsertPending(terms("m1"));
    await grants.activate(pending.id, { contactKey: KEY });
    assert.equal((await grants.get(pending.id))?.expiresAt, null);
  });

  it("não deixa outra conta ou outro número tomar a concessão", async () => {
    const grants = new GrantRepository();
    const pending = await grants.upsertPending(terms("m1"));
    await grants.activate(pending.id, { uid: GUEST, contactKey: KEY });
    assert.equal(await grants.activate(pending.id, { uid: "intruso" }), "other_account");
    assert.equal(await grants.activate(pending.id, { contactKey: "5511900000000" }), "other_account");
    assert.equal(await grants.activate(pending.id, { uid: GUEST }), "activated");
  });

  it("revogada não reativa, e um novo convite recomeça do zero", async () => {
    const grants = new GrantRepository();
    const pending = await grants.upsertPending(terms("m1"));
    await grants.activate(pending.id, { uid: GUEST });
    assert.equal(await grants.revoke(pending.id, OWNER), true);
    assert.equal(await grants.activate(pending.id, { uid: GUEST }), "revoked");

    const again = await grants.upsertPending(terms("m1"));
    assert.equal(again.status, "pending");
    assert.equal(again.principalUid, null);
  });

  it("mudar o prazo de uma concessão ativa recalcula a partir do aceite", async () => {
    const grants = new GrantRepository();
    const pending = await grants.upsertPending(terms("m1", { durationHours: 1 }));
    await grants.activate(pending.id, { uid: GUEST });
    const accepted = (await db.collection("access_grants").doc(pending.id).get()).get(
      "acceptedAt",
    ) as Timestamp;

    await grants.updateTerms("m1", { accessLevel: "readonly", permissions: [], durationHours: 5 });
    const updated = await grants.get(pending.id);
    assert.equal(updated?.accessLevel, "readonly");
    assert.equal(updated?.expiresAt?.toMillis(), accepted.toMillis() + 5 * 3600_000);

    await grants.updateTerms("m1", { accessLevel: "full", permissions: [], durationHours: null });
    assert.equal((await grants.get(pending.id))?.expiresAt, null);
  });

  it("encontra concessões vencidas ainda não marcadas", async () => {
    const grants = new GrantRepository();
    const pending = await grants.upsertPending(terms("m1", { durationHours: 1 }));
    await grants.activate(pending.id, { uid: GUEST });
    await db
      .collection("access_grants")
      .doc(pending.id)
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });

    assert.deepEqual((await grants.findExpiredActive()).map((g) => g.id), [pending.id]);
    await grants.markExpired(pending.id);
    assert.equal((await grants.findExpiredActive()).length, 0);
  });
});

describe("AccessService", () => {
  it("dona tem acesso total; estranho não tem acesso", async () => {
    const service = new AccessService();
    const owner = await service.resolve({ uid: OWNER, contactKey: null }, "r1");
    assert.equal(owner?.role, "owner");
    assert.equal(await service.resolve({ uid: "zeca", contactKey: null }, "r1"), null);
    assert.equal(await service.resolve({ uid: OWNER, contactKey: null }, "nao_existe"), null);
  });

  it("convidado acessa só com concessão ativa e dentro do prazo", async () => {
    const grants = new GrantRepository();
    const service = new AccessService(grants);
    const guest = { uid: GUEST, contactKey: null };

    const pending = await grants.upsertPending(terms("m1", { accessLevel: "partial", permissions: ["task"] }));
    assert.equal(await service.resolve(guest, "r1"), null);

    await grants.activate(pending.id, { uid: GUEST });
    const resolved = await service.resolve(guest, "r1");
    assert.equal(resolved?.role, "grantee");
    assert.equal(resolved?.level, "partial");
    assert.deepEqual(resolved?.permissions, ["task"]);

    await db
      .collection("access_grants")
      .doc(grantIdForMember("m1"))
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    assert.equal(await service.resolve(guest, "r1"), null);
  });

  it("número de WhatsApp acessa pela concessão ligada a ele", async () => {
    const grants = new GrantRepository();
    const service = new AccessService(grants);
    const pending = await grants.upsertPending(terms("m1"));
    await grants.activate(pending.id, { contactKey: KEY });
    assert.equal((await service.resolve({ uid: null, contactKey: KEY }, "r1"))?.role, "grantee");
    assert.equal(await service.resolve({ uid: null, contactKey: "5511900000000" }, "r1"), null);
  });

  it("lista próprios e compartilhados, em ordem, e filtra pelo canal", async () => {
    const grants = new GrantRepository();
    const service = new AccessService(grants);
    await seedRecipient("r3", "Ana", "outra_dona");

    const ro = await grants.upsertPending({
      ...terms("m1"),
      careRecipientId: "r3",
      ownerId: "outra_dona",
      accessLevel: "readonly",
    });
    await grants.activate(ro.id, { uid: OWNER });

    const all = await service.listAccessible({ uid: OWNER, contactKey: null });
    assert.deepEqual(
      all.map((item) => [item.careRecipientName, item.role]),
      [
        ["Ana", "grantee"],
        ["Lúcia", "owner"],
        ["Yuna", "owner"],
      ],
    );

    const whatsapp = await service.listAccessible({ uid: OWNER, contactKey: null }, "whatsapp");
    assert.deepEqual(
      whatsapp.map((item) => item.careRecipientName),
      ["Lúcia", "Yuna"],
    );
  });
});

describe("Permissões por nível e canal", () => {
  it("Acesso Total faz tudo; chat só no app", () => {
    const full = access({ level: "full" });
    assert.equal(canUseCora(full, "whatsapp"), true);
    assert.equal(canCreateTask(full), true);
    assert.equal(canRequestSos(full), true);
    assert.equal(canCreateChat(full, "app"), true);
    assert.equal(canCreateChat(full, "whatsapp"), false);
  });

  it("Apenas Visualização: Cora só no app, sem criar nada", () => {
    const ro = access({ level: "readonly" });
    assert.equal(canUseCora(ro, "app"), true);
    assert.equal(canUseCora(ro, "whatsapp"), false);
    assert.equal(canCreateTask(ro), false);
    assert.equal(canRequestSos(ro), false);
    assert.equal(canCreateChat(ro, "app"), false);
  });

  it("Parcial segue as áreas marcadas", () => {
    const partial = access({ level: "partial", permissions: ["cora", "task"] });
    assert.equal(canUseCora(partial, "whatsapp"), true);
    assert.equal(canCreateTask(partial), true);
    assert.equal(canRequestSos(partial), false);
    assert.equal(canCreateChat(partial, "app"), false);
    assert.equal(canUseCora(access({ level: "partial", permissions: ["task"] }), "whatsapp"), false);
  });

  it("dona faz tudo", () => {
    const owner = access({ role: "owner", level: "full" });
    assert.equal(canUseCora(owner, "whatsapp"), true);
    assert.equal(canCreateTask(owner), true);
    assert.equal(canRequestSos(owner), true);
  });
});

describe("DailyLimiter", () => {
  it("bloqueia ao atingir o limite e marca eventos uma vez por dia", async () => {
    const limiter = new DailyLimiter();
    assert.equal(await limiter.tryConsume("code_attempt", "uid:x", 2), true);
    assert.equal(await limiter.tryConsume("code_attempt", "uid:x", 2), true);
    assert.equal(await limiter.tryConsume("code_attempt", "uid:x", 2), false);
    assert.equal(await limiter.tryConsume("code_attempt", "uid:y", 2), true);

    assert.equal(await limiter.markOnce("notice", "wa:1", "quota"), true);
    assert.equal(await limiter.markOnce("notice", "wa:1", "quota"), false);
    assert.equal(await limiter.markOnce("notice", "wa:1", "readonly"), true);
  });
});
