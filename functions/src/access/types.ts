/*
 * CareHub Plus — Functions / Tipos de acesso compartilhado
 *
 * Vocabulário comum de concessões, identidades e permissões. A regra de
 * "quem pode fazer o quê" mora aqui em funções puras, para que app,
 * WhatsApp e testes decidam exatamente do mesmo jeito.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { Timestamp } from "firebase-admin/firestore";

export type AccessLevel = "full" | "partial" | "readonly";
export type Permission = "chat" | "cora" | "sos" | "task";
export type GrantStatus = "pending" | "active" | "revoked";
export type Channel = "app" | "whatsapp";

const LEVELS: AccessLevel[] = ["full", "partial", "readonly"];
const PERMISSIONS: Permission[] = ["chat", "cora", "sos", "task"];

/** Mesmo padrão do app: valor desconhecido vira "full" (NetworkMemberModel). */
export function toAccessLevel(value: unknown): AccessLevel {
  return LEVELS.includes(value as AccessLevel) ? (value as AccessLevel) : "full";
}

/** Ignora permissões desconhecidas, como o app faz. */
export function toPermissions(value: unknown): Permission[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is Permission => PERMISSIONS.includes(item as Permission));
}

/** Concessão gravada em `access_grants/{grantId}`. */
export interface AccessGrant {
  id: string;
  careRecipientId: string;
  ownerId: string;
  memberId: string;
  principalUid: string | null;
  principalContactKey: string | null;
  accessLevel: AccessLevel;
  permissions: Permission[];
  /** `null` = ilimitado. */
  durationHours: number | null;
  expiresAt: Timestamp | null;
  status: GrantStatus;
}

/** Concessão ativa e dentro do prazo. */
export function isGrantUsable(grant: AccessGrant, now = Date.now()): boolean {
  if (grant.status !== "active") return false;
  return grant.expiresAt === null || grant.expiresAt.toMillis() > now;
}

/**
 * Quem está pedindo: uma conta do app (`uid`), um número de WhatsApp
 * (`contactKey`) ou os dois, quando o número já foi ligado a uma conta.
 */
export interface Identity {
  uid: string | null;
  contactKey: string | null;
}

/** Chave estável da pessoa para cotas e sessões. */
export function principalKey(identity: Identity): string {
  if (identity.uid) return `uid:${identity.uid}`;
  if (identity.contactKey) return `wa:${identity.contactKey}`;
  throw new Error("Identidade vazia.");
}

/** Resultado da decisão de acesso a um assistido. */
export interface ResolvedAccess {
  careRecipientId: string;
  careRecipientName: string;
  ownerId: string;
  role: "owner" | "grantee";
  level: AccessLevel;
  permissions: Permission[];
  grantId: string | null;
}

function hasArea(access: ResolvedAccess, area: Permission): boolean {
  if (access.role === "owner" || access.level === "full") return true;
  return access.level === "partial" && access.permissions.includes(area);
}

/**
 * Pode conversar com a Cora sobre o assistido.
 * No app, "Apenas Visualização" consulta; no WhatsApp, não tem acesso.
 */
export function canUseCora(access: ResolvedAccess, channel: Channel): boolean {
  if (access.role === "owner" || access.level === "full") return true;
  if (access.level === "readonly") return channel === "app";
  return access.permissions.includes("cora");
}

export function canCreateTask(access: ResolvedAccess): boolean {
  return access.level !== "readonly" && hasArea(access, "task");
}

/** Chat existe só no app. */
export function canCreateChat(access: ResolvedAccess, channel: Channel): boolean {
  return channel === "app" && access.level !== "readonly" && hasArea(access, "chat");
}

export function canRequestSos(access: ResolvedAccess): boolean {
  return access.level !== "readonly" && hasArea(access, "sos");
}
