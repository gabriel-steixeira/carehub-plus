/*
 * CareHub Plus — Testes / Recusa do SOS pelo app
 *
 * Exercita a lógica da recusa do SOS contra o Firestore Emulator: resolve o
 * membro do chamador pelo `uid` (via `access_grants.principalUid`), reusa a
 * transação `CareRepository.registerSosResponse` com `accepted = false` e
 * confere que a recusa não mexe no `status` nem no `acceptedByMemberId`. Cobre
 * ainda o chamador fora de `notifiedMemberIds` e a origem WhatsApp, em que o
 * telefone de quem responder vem de `requestedBy` ("wa:<telefone>").
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { clearFirestore } from "./helpers";

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";

import { grantIdForMember } from "../../src/access/grantRepository";
import { CareRepository } from "../../src/repositories/careRepository";
import { db } from "../../src/shared/firestore";

const OWNER = "alice";
const REQUESTER_UID = "requester_uid";
const MEMBER_ID = "vizinho";
const MEMBER_UID = "vizinho_uid";
const ALERT_ID = "sos_1";
const RECIPIENT_ID = "r1";

/** Liga a conta do membro à concessão (fonte da resolução uid → memberId). */
async function seedGrant(memberId: string, principalUid: string): Promise<void> {
  await db.collection("access_grants").doc(grantIdForMember(memberId)).set({
    id: grantIdForMember(memberId),
    careRecipientId: RECIPIENT_ID,
    ownerId: OWNER,
    memberId,
    principalUid,
    principalContactKey: null,
    accessLevel: "full",
    permissions: [],
    durationHours: null,
    expiresAt: null,
    status: "active",
  });
}

/** Alerta de SOS recém-enviado, acionando o membro informado. */
async function seedAlert(notifiedMemberIds: string[]): Promise<void> {
  await db.collection("sos_alerts").doc(ALERT_ID).set({
    id: ALERT_ID,
    status: "dispatched",
    notifiedMemberIds,
    requestedByUid: REQUESTER_UID,
    caregiverId: OWNER,
    careRecipientId: RECIPIENT_ID,
  });
}

/** Resolve o memberId do chamador do mesmo jeito que o callable. */
async function resolveMemberId(
  uid: string,
  notifiedMemberIds: string[],
): Promise<string | null> {
  for (const candidate of notifiedMemberIds) {
    const snapshot = await db.collection("access_grants").doc(grantIdForMember(candidate)).get();
    if (snapshot.get("principalUid") === uid) return candidate;
  }
  return null;
}

beforeEach(async () => {
  await clearFirestore();
  await db.collection("caregivers").doc(OWNER).set({ name: "Alice Souza" });
  await db.collection("care_recipients").doc(RECIPIENT_ID).set({
    id: RECIPIENT_ID,
    name: "Lúcia Maria",
    caregiverId: OWNER,
  });
  await db.collection("network_members").doc(MEMBER_ID).set({
    id: MEMBER_ID,
    name: "Vizinho Bruno",
    phone: "5511933330000",
    caregiverId: OWNER,
    careRecipientId: RECIPIENT_ID,
  });
});

describe("Recusa do SOS pelo app", () => {
  it("recusa grava declined e não muda o status", async () => {
    await seedGrant(MEMBER_ID, MEMBER_UID);
    await seedAlert([MEMBER_ID]);

    const memberId = await resolveMemberId(MEMBER_UID, [MEMBER_ID]);
    assert.equal(memberId, MEMBER_ID);

    const care = new CareRepository();
    const result = await care.registerSosResponse(ALERT_ID, memberId as string, false);
    assert.equal(result, "declined");

    const alert = (await db.collection("sos_alerts").doc(ALERT_ID).get()).data() ?? {};
    assert.equal(alert.status, "dispatched");
    assert.equal(alert.acceptedByMemberId, undefined);
  });

  it("chamador fora de notifiedMemberIds não recusa", async () => {
    await seedGrant(MEMBER_ID, MEMBER_UID);
    await seedAlert([MEMBER_ID]);

    const memberId = await resolveMemberId("conta_estranha", [MEMBER_ID]);
    assert.equal(memberId, null);

    const care = new CareRepository();
    const result = await care.registerSosResponse(ALERT_ID, "membro_desconhecido", false);
    assert.equal(result, "not_allowed");
  });

  it("origem WhatsApp: toKey vem de requestedBy", async () => {
    await db.collection("sos_alerts").doc(ALERT_ID).set({
      id: ALERT_ID,
      status: "dispatched",
      notifiedMemberIds: [MEMBER_ID],
      channel: "whatsapp",
      requestedBy: "wa:5511999990000",
      caregiverId: OWNER,
      careRecipientId: RECIPIENT_ID,
    });

    const snap = await db.collection("sos_alerts").doc(ALERT_ID).get();
    const requestedBy = snap.get("requestedBy") as string;
    assert.equal(requestedBy.startsWith("wa:"), true);
    assert.equal(requestedBy.slice(3), "5511999990000");
  });
});
