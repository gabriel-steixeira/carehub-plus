/*
 * CareHub Plus — Functions / Decisão de acesso a assistidos
 *
 * Responde, no servidor, "esta pessoa pode acessar este assistido, e com
 * qual nível?". É a mesma regra do firestore.rules, usada pelas callables,
 * pela Cora e pelo WhatsApp. A identidade vem sempre de uma prova (UID do
 * Auth ou número assinado pela Meta), nunca do modelo de IA.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { db } from "../shared/firestore";
import { GrantRepository } from "./grantRepository";
import { AccessGrant, canUseCora, Channel, Identity, isGrantUsable, ResolvedAccess } from "./types";

export class AccessService {
  constructor(private readonly grants = new GrantRepository()) {}

  /** Acesso a um assistido específico, ou `null` se a pessoa não pode acessá-lo. */
  async resolve(identity: Identity, careRecipientId: string): Promise<ResolvedAccess | null> {
    if (!careRecipientId) return null;
    const recipient = await db.collection("care_recipients").doc(careRecipientId).get();
    if (!recipient.exists) return null;

    const ownerId = (recipient.get("caregiverId") as string | undefined) ?? "";
    const name = (recipient.get("name") as string | undefined) ?? "";

    if (identity.uid && ownerId === identity.uid) {
      return this.ownerAccess(careRecipientId, name, ownerId);
    }

    const query = await db
      .collection("access_grants")
      .where("careRecipientId", "==", careRecipientId)
      .where("status", "==", "active")
      .get();

    const grant = query.docs
      .map((doc) => this.grants.toGrant(doc))
      .find((item) => this.belongsTo(item, identity) && isGrantUsable(item));

    return grant ? this.granteeAccess(grant, name) : null;
  }

  /**
   * Todos os assistidos que a pessoa pode acessar, em ordem alfabética. Com
   * `channel`, mantém só os que permitem a Cora naquele canal.
   */
  async listAccessible(identity: Identity, channel?: Channel): Promise<ResolvedAccess[]> {
    const byRecipient = new Map<string, ResolvedAccess>();

    if (identity.uid) {
      const owned = await db
        .collection("care_recipients")
        .where("caregiverId", "==", identity.uid)
        .get();
      for (const doc of owned.docs) {
        byRecipient.set(
          doc.id,
          this.ownerAccess(doc.id, (doc.get("name") as string | undefined) ?? "", identity.uid),
        );
      }
    }

    const grants: AccessGrant[] = [
      ...(identity.uid ? await this.grants.findUsableByUid(identity.uid) : []),
      ...(identity.contactKey ? await this.grants.findUsableByContactKey(identity.contactKey) : []),
    ].filter((grant) => !byRecipient.has(grant.careRecipientId));

    const names = await this.recipientNames(grants.map((grant) => grant.careRecipientId));
    for (const grant of grants) {
      if (byRecipient.has(grant.careRecipientId)) continue;
      byRecipient.set(
        grant.careRecipientId,
        this.granteeAccess(grant, names.get(grant.careRecipientId) ?? ""),
      );
    }

    return [...byRecipient.values()]
      .filter((access) => (channel ? canUseCora(access, channel) : true))
      .sort((left, right) => left.careRecipientName.localeCompare(right.careRecipientName, "pt-BR"));
  }

  private belongsTo(grant: AccessGrant, identity: Identity): boolean {
    return (
      (!!identity.uid && grant.principalUid === identity.uid) ||
      (!!identity.contactKey && grant.principalContactKey === identity.contactKey)
    );
  }

  private async recipientNames(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)].filter(Boolean);
    if (unique.length === 0) return new Map();
    const snapshots = await db.getAll(...unique.map((id) => db.collection("care_recipients").doc(id)));
    return new Map(
      snapshots
        .filter((snapshot) => snapshot.exists)
        .map((snapshot) => [snapshot.id, (snapshot.get("name") as string | undefined) ?? ""]),
    );
  }

  private ownerAccess(careRecipientId: string, name: string, ownerId: string): ResolvedAccess {
    return {
      careRecipientId,
      careRecipientName: name,
      ownerId,
      role: "owner",
      level: "full",
      permissions: [],
      grantId: null,
    };
  }

  private granteeAccess(grant: AccessGrant, name: string): ResolvedAccess {
    return {
      careRecipientId: grant.careRecipientId,
      careRecipientName: name,
      ownerId: grant.ownerId,
      role: "grantee",
      level: grant.accessLevel,
      permissions: grant.permissions,
      grantId: grant.id,
    };
  }
}
