/*
 * CareHub Plus — Functions / Repositório de concessões de acesso
 *
 * Única porta de gravação de `access_grants`. Cada membro da rede tem no
 * máximo uma concessão (id `member_<memberId>`), que nasce pendente no
 * convite, fica ativa no aceite e termina revogada. O prazo começa a contar
 * no aceite. As regras do Firestore impedem o app de gravar aqui.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { DocumentSnapshot, FieldValue, Timestamp } from "firebase-admin/firestore";

import { db } from "../shared/firestore";
import {
  AccessGrant,
  AccessLevel,
  GrantStatus,
  isGrantUsable,
  Permission,
  toAccessLevel,
  toPermissions,
} from "./types";

const HOUR_MS = 60 * 60 * 1000;

export interface GrantTerms {
  careRecipientId: string;
  ownerId: string;
  memberId: string;
  accessLevel: AccessLevel;
  permissions: Permission[];
  durationHours: number | null;
}

export interface PrincipalLink {
  uid?: string | null;
  contactKey?: string | null;
}

export type ActivateResult = "activated" | "not_found" | "revoked" | "other_account";

export function grantIdForMember(memberId: string): string {
  return `member_${memberId}`;
}

/** Converte o prazo digitado em horas (inteiro positivo) ou `null` (ilimitado). */
export function toDurationHours(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) return null;
  return Math.round(value);
}

export class GrantRepository {
  private readonly grants = db.collection("access_grants");

  async get(grantId: string): Promise<AccessGrant | null> {
    const snapshot = await this.grants.doc(grantId).get();
    return snapshot.exists ? this.toGrant(snapshot) : null;
  }

  async getByMember(memberId: string): Promise<AccessGrant | null> {
    return this.get(grantIdForMember(memberId));
  }

  /**
   * Prepara a concessão para um convite. Uma concessão ativa continua ativa
   * (só os termos são atualizados); uma revogada ou inexistente recomeça
   * pendente, sem nenhuma pessoa vinculada.
   */
  async upsertPending(terms: GrantTerms): Promise<AccessGrant> {
    const ref = this.grants.doc(grantIdForMember(terms.memberId));
    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      const status = snapshot.get("status") as GrantStatus | undefined;
      const base = {
        careRecipientId: terms.careRecipientId,
        ownerId: terms.ownerId,
        memberId: terms.memberId,
        accessLevel: terms.accessLevel,
        permissions: terms.permissions,
        durationHours: terms.durationHours,
        updatedAt: FieldValue.serverTimestamp(),
      };

      if (status === "active" || status === "pending") {
        tx.update(ref, { ...base, ...this.expiryUpdate(snapshot, terms.durationHours) });
        return;
      }

      tx.set(ref, {
        ...base,
        principalUid: null,
        principalContactKey: null,
        expiresAt: null,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
        acceptedAt: null,
        revokedAt: null,
        revokedBy: null,
      });
    });
    return (await this.get(ref.id)) as AccessGrant;
  }

  /**
   * Ativa a concessão e liga a conta e/ou o número a ela. Na primeira
   * ativação, o prazo começa a contar. Uma concessão já ligada a outra
   * conta ou a outro número não é tomada.
   */
  async activate(grantId: string, link: PrincipalLink): Promise<ActivateResult> {
    const ref = this.grants.doc(grantId);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) return "not_found";
      const status = snapshot.get("status") as GrantStatus;
      if (status === "revoked") return "revoked";

      const currentUid = snapshot.get("principalUid") as string | null;
      const currentKey = snapshot.get("principalContactKey") as string | null;
      if (link.uid && currentUid && currentUid !== link.uid) return "other_account";
      if (link.contactKey && currentKey && currentKey !== link.contactKey) {
        return "other_account";
      }

      const update: Record<string, unknown> = {
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (link.uid) update.principalUid = link.uid;
      if (link.contactKey) update.principalContactKey = link.contactKey;

      if (status === "pending") {
        const now = Date.now();
        const hours = toDurationHours(snapshot.get("durationHours"));
        update.status = "active";
        update.acceptedAt = Timestamp.fromMillis(now);
        update.expiresAt = hours === null ? null : Timestamp.fromMillis(now + hours * HOUR_MS);
      }

      tx.update(ref, update);
      return "activated";
    });
  }

  async revoke(grantId: string, revokedBy: string): Promise<boolean> {
    const ref = this.grants.doc(grantId);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists || snapshot.get("status") === "revoked") return false;
      tx.update(ref, {
        status: "revoked",
        revokedAt: FieldValue.serverTimestamp(),
        revokedBy,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /** A dona editou o membro: nível, permissões ou prazo mudam na concessão. */
  async updateTerms(
    memberId: string,
    terms: Pick<GrantTerms, "accessLevel" | "permissions" | "durationHours">,
  ): Promise<void> {
    const ref = this.grants.doc(grantIdForMember(memberId));
    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists || snapshot.get("status") === "revoked") return;
      tx.update(ref, {
        accessLevel: terms.accessLevel,
        permissions: terms.permissions,
        durationHours: terms.durationHours,
        ...this.expiryUpdate(snapshot, terms.durationHours),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  /** Concessões ativas e dentro do prazo ligadas a uma conta. */
  async findUsableByUid(uid: string): Promise<AccessGrant[]> {
    const query = await this.grants
      .where("principalUid", "==", uid)
      .where("status", "==", "active")
      .get();
    return query.docs.map((doc) => this.toGrant(doc)).filter((grant) => isGrantUsable(grant));
  }

  /** Concessões ativas e dentro do prazo ligadas a um número. */
  async findUsableByContactKey(contactKey: string): Promise<AccessGrant[]> {
    const query = await this.grants
      .where("principalContactKey", "==", contactKey)
      .where("status", "==", "active")
      .get();
    return query.docs.map((doc) => this.toGrant(doc)).filter((grant) => isGrantUsable(grant));
  }

  /** Todas as concessões ligadas a um número, inclusive sem acesso agora. */
  async findAnyByContactKey(contactKey: string): Promise<AccessGrant[]> {
    const query = await this.grants.where("principalContactKey", "==", contactKey).get();
    return query.docs.map((doc) => this.toGrant(doc));
  }

  /**
   * Concessões ativas cujo prazo já venceu e que a limpeza ainda não marcou.
   * Filtra só por `expiresAt` (índice simples, automático) e confere o resto
   * em memória, para não exigir índice composto em produção.
   */
  async findExpiredActive(now = Date.now()): Promise<AccessGrant[]> {
    const query = await this.grants.where("expiresAt", "<=", Timestamp.fromMillis(now)).get();
    return query.docs
      .filter((doc) => doc.get("status") === "active" && !doc.get("expiredAt"))
      .map((doc) => this.toGrant(doc));
  }

  /** Marca que a limpeza viu o vencimento (dispara a atualização do espelho). */
  async markExpired(grantId: string): Promise<void> {
    await this.grants.doc(grantId).update({ expiredAt: FieldValue.serverTimestamp() });
  }

  /** Recalcula `expiresAt` a partir do aceite quando o prazo muda. */
  private expiryUpdate(
    snapshot: DocumentSnapshot,
    durationHours: number | null,
  ): Record<string, unknown> {
    const acceptedAt = snapshot.get("acceptedAt") as Timestamp | null | undefined;
    if (!acceptedAt) return {};
    return {
      expiresAt:
        durationHours === null
          ? null
          : Timestamp.fromMillis(acceptedAt.toMillis() + durationHours * HOUR_MS),
    };
  }

  toGrant(snapshot: DocumentSnapshot): AccessGrant {
    const data = snapshot.data() ?? {};
    return {
      id: snapshot.id,
      careRecipientId: (data.careRecipientId as string | undefined) ?? "",
      ownerId: (data.ownerId as string | undefined) ?? "",
      memberId: (data.memberId as string | undefined) ?? "",
      principalUid: (data.principalUid as string | null | undefined) ?? null,
      principalContactKey: (data.principalContactKey as string | null | undefined) ?? null,
      accessLevel: toAccessLevel(data.accessLevel),
      permissions: toPermissions(data.permissions),
      durationHours: toDurationHours(data.durationHours),
      expiresAt: (data.expiresAt as Timestamp | null | undefined) ?? null,
      status: ((data.status as GrantStatus | undefined) ?? "pending") as GrantStatus,
    };
  }
}
