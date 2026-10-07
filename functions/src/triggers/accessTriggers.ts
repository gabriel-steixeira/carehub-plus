/*
 * CareHub Plus — Functions / Triggers de acesso compartilhado
 *
 * - onAccessGrantWritten: espelha a concessão no assistido e no membro.
 * - onNetworkMemberWritten: quando a dona edita nível, permissões ou prazo
 *   do membro, a concessão acompanha; quando remove o membro, o acesso cai.
 * - cleanupExpiredAccess: de hora em hora tira do espelho quem venceu. É só
 *   arrumação — o bloqueio por prazo já vale nas regras e no backend.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { GrantRepository, grantIdForMember, toDurationHours } from "../access/grantRepository";
import { mirrorGrant } from "../access/grantMirror";
import { cancelInvitesOfMember } from "../access/inviteService";
import { toAccessLevel, toPermissions } from "../access/types";
import { APP_TIME_ZONE, REGION } from "../config";

export const onAccessGrantWritten = onDocumentWritten(
  { document: "access_grants/{grantId}", region: REGION },
  async (event) => {
    await mirrorGrant(
      event.params.grantId,
      event.data?.before.data(),
      event.data?.after.data(),
    );
  },
);

/** Campos do membro que mudam os termos da concessão. */
const TERM_FIELDS = ["accessLevel", "permissions", "accessDurationHours"] as const;

export async function syncMemberToGrant(
  memberId: string,
  before: FirebaseFirestore.DocumentData | undefined,
  after: FirebaseFirestore.DocumentData | undefined,
  grants = new GrantRepository(),
): Promise<void> {
  if (!after) {
    await cancelInvitesOfMember(memberId);
    await grants.revoke(grantIdForMember(memberId), "member_removed");
    return;
  }

  const changed = TERM_FIELDS.some(
    (field) => JSON.stringify(before?.[field] ?? null) !== JSON.stringify(after[field] ?? null),
  );
  if (!before || !changed) return;

  const accessLevel = toAccessLevel(after.accessLevel);
  await grants.updateTerms(memberId, {
    accessLevel,
    permissions: accessLevel === "partial" ? toPermissions(after.permissions) : [],
    durationHours: toDurationHours(after.accessDurationHours),
  });
}

export const onNetworkMemberWritten = onDocumentWritten(
  { document: "network_members/{memberId}", region: REGION },
  async (event) => {
    await syncMemberToGrant(
      event.params.memberId,
      event.data?.before.data(),
      event.data?.after.data(),
    );
  },
);

export async function cleanupExpired(grants = new GrantRepository()): Promise<number> {
  const expired = await grants.findExpiredActive();
  await Promise.all(expired.map((grant) => grants.markExpired(grant.id)));
  return expired.length;
}

export const cleanupExpiredAccess = onSchedule(
  { schedule: "every 60 minutes", timeZone: APP_TIME_ZONE, region: REGION },
  async () => {
    const count = await cleanupExpired();
    if (count > 0) logger.info("Acessos vencidos retirados do espelho.", { count });
  },
);
