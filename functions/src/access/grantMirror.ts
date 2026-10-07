/*
 * CareHub Plus — Functions / Espelho das concessões
 *
 * Mantém `care_recipients/{id}.accessUids` e `.access.<uid>` iguais às
 * concessões utilizáveis, para que as regras do Firestore decidam com um
 * único get(). Também atualiza a situação exibida no card do membro
 * (`network_members.inviteStatus` e `accessExpiresAt`). Só o backend grava.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { FieldPath, FieldValue, Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import { db } from "../shared/firestore";
import { GrantRepository } from "./grantRepository";
import { AccessGrant, isGrantUsable } from "./types";

export type InviteStatus = "none" | "pending" | "active" | "expired" | "revoked";

const NOT_FOUND = 5; // código gRPC do Firestore

export function inviteStatusOf(grant: AccessGrant | null, now = Date.now()): InviteStatus {
  if (!grant) return "none";
  if (grant.status === "revoked") return "revoked";
  if (grant.status === "pending") return "pending";
  return isGrantUsable(grant, now) ? "active" : "expired";
}

/**
 * Aplica no assistido e no membro o estado atual da concessão. `before` e
 * `after` são os dados do documento antes e depois da escrita.
 */
export async function mirrorGrant(
  grantId: string,
  before: FirebaseFirestore.DocumentData | undefined,
  after: FirebaseFirestore.DocumentData | undefined,
  grants = new GrantRepository(),
): Promise<void> {
  const afterGrant = after ? grants.toGrant(fakeSnapshot(grantId, after)) : null;
  const beforeUid = (before?.principalUid as string | null | undefined) ?? null;
  const recipientId =
    afterGrant?.careRecipientId || ((before?.careRecipientId as string | undefined) ?? "");
  if (!recipientId) return;

  const recipientRef = db.collection("care_recipients").doc(recipientId);
  const update: unknown[] = [];

  if (afterGrant?.principalUid && isGrantUsable(afterGrant)) {
    update.push(
      new FieldPath("access", afterGrant.principalUid),
      {
        level: afterGrant.accessLevel,
        permissions: afterGrant.permissions,
        expiresAt: afterGrant.expiresAt,
      },
      "accessUids",
      FieldValue.arrayUnion(afterGrant.principalUid),
    );
  } else if (afterGrant?.principalUid) {
    update.push(...removal(afterGrant.principalUid));
  }

  if (beforeUid && beforeUid !== afterGrant?.principalUid) {
    update.push(...removal(beforeUid));
  }

  if (update.length > 0) {
    try {
      const [first, second, ...rest] = update;
      await recipientRef.update(first as FieldPath, second, ...rest);
    } catch (error) {
      // Assistido apagado: não há o que espelhar.
      if ((error as { code?: number })?.code !== NOT_FOUND) throw error;
    }
  }

  const memberId = afterGrant?.memberId || ((before?.memberId as string | undefined) ?? "");
  if (memberId) await updateMemberStatus(memberId, grantId, afterGrant);
}

function removal(uid: string): unknown[] {
  return [new FieldPath("access", uid), FieldValue.delete(), "accessUids", FieldValue.arrayRemove(uid)];
}

async function updateMemberStatus(
  memberId: string,
  grantId: string,
  grant: AccessGrant | null,
): Promise<void> {
  const ref = db.collection("network_members").doc(memberId);
  const snapshot = await ref.get();
  if (!snapshot.exists) return;

  const status = inviteStatusOf(grant);
  const expiresAt = grant?.expiresAt ?? null;
  const unchanged =
    snapshot.get("inviteStatus") === status &&
    snapshot.get("grantId") === grantId &&
    sameTimestamp(snapshot.get("accessExpiresAt") as Timestamp | null | undefined, expiresAt);
  if (unchanged) return;

  await ref.update({ inviteStatus: status, grantId, accessExpiresAt: expiresAt });
  logger.info("Situação do convite atualizada.", { memberId, status });
}

function sameTimestamp(left: Timestamp | null | undefined, right: Timestamp | null): boolean {
  return (left?.toMillis() ?? null) === (right?.toMillis() ?? null);
}

/** Adapta dados soltos ao `toGrant`, que espera um snapshot. */
function fakeSnapshot(id: string, data: FirebaseFirestore.DocumentData) {
  return { id, data: () => data } as unknown as FirebaseFirestore.DocumentSnapshot;
}
