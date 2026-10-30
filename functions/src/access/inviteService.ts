/*
 * CareHub Plus — Functions / Convites da rede de apoio
 *
 * Cria, cancela e aceita convites. O código de 6 caracteres é a prova de que
 * a pessoa recebeu o convite; só o hash dele fica gravado. Pelo WhatsApp, o
 * número que envia o código também precisa ser o telefone cadastrado no
 * membro, então um convite repassado num grupo não funciona. O envio do
 * convite sai do aparelho da própria dona (sem custo de WhatsApp).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { createHash, randomInt } from "node:crypto";

import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import { INVITE_TTL_MS, SELF_LINK_TTL_MS } from "../config";
import { CareRepository } from "../repositories/careRepository";
import { DailyLimiter } from "../shared/dailyLimiter";
import { db, maskPhone } from "../shared/firestore";
import { contactKey, toWhatsAppNumber } from "../shared/phone";
import { firstName } from "../shared/text";
import { mirrorGrant } from "./grantMirror";
import { GrantRepository, grantIdForMember, toDurationHours } from "./grantRepository";
import { Channel, toAccessLevel, toPermissions } from "./types";

/** Sem 0/O, 1/I/L: fácil de ler e de digitar. */
const CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
const CODE_LENGTH = 6;

/** Mensagem que a pessoa envia pelo WhatsApp para aceitar. */
export const ENTRY_COMMAND = "ENTRAR";

export type InviteChannel = Channel | "self";

export type InviteErrorCode =
  | "not-found"
  | "permission-denied"
  | "failed-precondition"
  | "resource-exhausted"
  | "invalid-argument";

/** Erro conhecido, com mensagem pronta para mostrar à pessoa. */
export class InviteError extends Error {
  constructor(
    readonly code: InviteErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "InviteError";
  }
}

/** Mesma mensagem para código inexistente, usado ou vencido: não revela nada. */
const INVALID_CODE_MESSAGE = "Código inválido ou vencido. Peça um novo convite.";

export interface InviteLimits {
  invitesPerDay: number;
  codeAttemptsPerDay: number;
}

export interface CreatedInvite {
  code: string;
  expiresAt: string;
  channel: Channel;
  /** Texto pronto para a dona enviar. */
  shareText: string;
  /** Abre o WhatsApp da dona já na conversa com o membro (ou `null`). */
  shareLink: string | null;
}

export interface SelfLinkCode {
  code: string;
  expiresAt: string;
  /** Abre o WhatsApp da dona na conversa com o CareHub, já com o texto. */
  link: string;
}

export interface RedeemedAccess {
  careRecipientId: string;
  careRecipientName: string;
}

export type WhatsAppAcceptResult =
  | { kind: "accepted"; recipientFirstName: string }
  | { kind: "self_linked" }
  | { kind: "readonly"; recipientFirstName: string }
  | { kind: "invalid" }
  | { kind: "rate_limited" };

interface InviteRecord {
  id: string;
  grantId: string | null;
  memberId: string | null;
  careRecipientId: string | null;
  ownerId: string;
  channel: InviteChannel;
  email: string | null;
  contactKey: string | null;
  expiresAt: Timestamp;
  status: "pending" | "used" | "cancelled";
}

export function normalizeCode(raw: string): string {
  return raw.toUpperCase().replace(/[^0-9A-Z]/g, "");
}

export function hashCode(code: string): string {
  return createHash("sha256").update(normalizeCode(code)).digest("hex");
}

export function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  }
  return code;
}

/** Lê "ENTRAR 7F3K9Q" (com ou sem espaço, maiúsculas ou não). */
export function parseEntryCommand(text: string): string | null {
  const match = /^\s*entrar\s*[:\-]?\s*([0-9a-z]{6})\s*$/i.exec(text);
  return match ? normalizeCode(match[1]) : null;
}

function waLink(number: string, text: string): string {
  return `https://wa.me/${number}?text=${encodeURIComponent(text)}`;
}

export class InviteService {
  private readonly invites = db.collection("invites");

  constructor(
    /** Número do WhatsApp do CareHub (só dígitos), para o link `wa.me`. */
    private readonly carehubNumber: string,
    private readonly limits: InviteLimits,
    private readonly grants = new GrantRepository(),
    private readonly care = new CareRepository(),
    private readonly limiter = new DailyLimiter(),
  ) {}

  /** A dona convida um membro da rede, pelo app ou pelo WhatsApp. */
  async createInvite(ownerUid: string, memberId: string, channel: Channel): Promise<CreatedInvite> {
    const memberSnapshot = await db.collection("network_members").doc(memberId).get();
    const member = memberSnapshot.data();
    if (!memberSnapshot.exists || !member || member.caregiverId !== ownerUid) {
      throw new InviteError("not-found", "Membro não encontrado na sua rede de apoio.");
    }

    const careRecipientId = member.careRecipientId as string | undefined;
    const recipientOwner = await this.care.getCareRecipientOwnerId(careRecipientId);
    if (!careRecipientId || recipientOwner !== ownerUid) {
      throw new InviteError(
        "failed-precondition",
        "Vincule o membro a um perfil de cuidado antes de convidar.",
      );
    }

    const accessLevel = toAccessLevel(member.accessLevel);
    if (channel === "whatsapp" && accessLevel === "readonly") {
      throw new InviteError(
        "failed-precondition",
        "O nível Apenas Visualização não inclui o WhatsApp. Envie o convite pelo app.",
      );
    }

    const memberNumber = toWhatsAppNumber(member.phone as string | undefined);
    if (channel === "whatsapp" && !memberNumber) {
      throw new InviteError("invalid-argument", "Cadastre um telefone válido para convidar pelo WhatsApp.");
    }
    if (channel === "whatsapp" && !this.carehubNumber) {
      throw new InviteError(
        "failed-precondition",
        "O WhatsApp do CareHub ainda não foi configurado. Envie o convite pelo app.",
      );
    }

    if (!(await this.limiter.tryConsume("invite_create", ownerUid, this.limits.invitesPerDay))) {
      throw new InviteError("resource-exhausted", "Você atingiu o limite de convites de hoje.");
    }

    const grant = await this.grants.upsertPending({
      careRecipientId,
      ownerId: ownerUid,
      memberId,
      accessLevel,
      permissions: accessLevel === "partial" ? toPermissions(member.permissions) : [],
      durationHours: toDurationHours(member.accessDurationHours),
    });

    await this.cancelPendingForMember(memberId);

    const code = generateCode();
    const expiresAt = Timestamp.fromMillis(Date.now() + INVITE_TTL_MS);
    const email = ((member.email as string | undefined) ?? "").trim().toLowerCase() || null;
    await this.invites.add({
      codeHash: hashCode(code),
      grantId: grant.id,
      memberId,
      careRecipientId,
      ownerId: ownerUid,
      channel,
      email,
      contactKey: memberNumber ? contactKey(memberNumber) : null,
      expiresAt,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      usedAt: null,
    });

    const [ownerName, recipientName] = await Promise.all([
      this.care.getCaregiverName(ownerUid),
      this.care.getCareRecipientName(careRecipientId),
    ]);
    const shareText = this.buildShareText({
      channel,
      code,
      memberName: member.name as string | undefined,
      ownerName,
      recipientName,
    });

    logger.info("Convite criado.", { memberId, channel });
    return {
      code,
      expiresAt: expiresAt.toDate().toISOString(),
      channel,
      shareText,
      shareLink: memberNumber ? waLink(memberNumber, shareText) : null,
    };
  }

  /** Cancela o convite pendente; uma concessão ainda pendente é revogada. */
  async cancelInvite(ownerUid: string, memberId: string): Promise<void> {
    const grant = await this.grants.getByMember(memberId);
    if (!grant || grant.ownerId !== ownerUid) {
      throw new InviteError("not-found", "Convite não encontrado.");
    }
    await this.cancelPendingForMember(memberId);
    if (grant.status === "pending") await this.grants.revoke(grant.id, ownerUid);
  }

  /** Remove o acesso imediatamente, no app e no WhatsApp. */
  async revokeAccess(ownerUid: string, memberId: string): Promise<void> {
    const grant = await this.grants.getByMember(memberId);
    if (!grant || grant.ownerId !== ownerUid) {
      throw new InviteError("not-found", "Acesso não encontrado.");
    }
    await this.cancelPendingForMember(memberId);
    await this.grants.revoke(grant.id, ownerUid);
    logger.info("Acesso revogado.", { memberId });
  }

  /** Tela "Tenho um convite": a conta logada usa o código. */
  async redeemCode(uid: string, rawCode: string): Promise<RedeemedAccess> {
    if (!(await this.limiter.tryConsume("code_attempt", `uid:${uid}`, this.limits.codeAttemptsPerDay))) {
      throw new InviteError(
        "resource-exhausted",
        "Muitas tentativas hoje. Tente de novo amanhã ou peça um novo convite.",
      );
    }

    const invite = await this.findPendingByCode(rawCode);
    if (!invite || invite.channel === "self" || !invite.grantId || !invite.careRecipientId) {
      throw new InviteError("not-found", INVALID_CODE_MESSAGE);
    }
    if (invite.ownerId === uid) {
      throw new InviteError("failed-precondition", "Este convite foi criado por você mesma.");
    }

    const result = await this.grants.activate(invite.grantId, { uid });
    if (result === "other_account") {
      throw new InviteError("failed-precondition", "Este convite já foi usado por outra conta.");
    }
    if (result !== "activated") throw new InviteError("not-found", INVALID_CODE_MESSAGE);

    await this.mirrorNow(invite.grantId);
    await this.markUsed(invite.id);
    return {
      careRecipientId: invite.careRecipientId,
      careRecipientName: (await this.care.getCareRecipientName(invite.careRecipientId)) ?? "",
    };
  }

  /**
   * Ao entrar no app: ativa os convites pendentes enviados para o e-mail da
   * conta. Só com e-mail verificado — o e-mail digitado sem verificação não
   * prova nada.
   */
  async claimByVerifiedEmail(
    uid: string,
    email: string | undefined,
    emailVerified: boolean,
  ): Promise<RedeemedAccess[]> {
    const normalized = (email ?? "").trim().toLowerCase();
    if (!emailVerified || !normalized) return [];

    const query = await this.invites
      .where("email", "==", normalized)
      .where("status", "==", "pending")
      .get();

    const claimed: RedeemedAccess[] = [];
    for (const doc of query.docs) {
      const invite = this.toInvite(doc.id, doc.data());
      if (invite.channel === "self" || invite.ownerId === uid || !invite.grantId) continue;
      if (invite.expiresAt.toMillis() <= Date.now() || !invite.careRecipientId) continue;
      if ((await this.grants.activate(invite.grantId, { uid })) !== "activated") continue;
      await this.mirrorNow(invite.grantId);
      await this.markUsed(invite.id);
      claimed.push({
        careRecipientId: invite.careRecipientId,
        careRecipientName: (await this.care.getCareRecipientName(invite.careRecipientId)) ?? "",
      });
    }
    if (claimed.length > 0) logger.info("Convites aceitos por e-mail verificado.", { count: claimed.length });
    return claimed;
  }

  /** A dona pede um código para ligar o próprio WhatsApp à conta. */
  async createSelfLinkCode(ownerUid: string): Promise<SelfLinkCode> {
    if (!this.carehubNumber) {
      throw new InviteError("failed-precondition", "O WhatsApp do CareHub ainda não foi configurado.");
    }
    if (!(await this.limiter.tryConsume("invite_create", ownerUid, this.limits.invitesPerDay))) {
      throw new InviteError("resource-exhausted", "Você atingiu o limite de códigos de hoje.");
    }

    const pending = await this.invites
      .where("ownerId", "==", ownerUid)
      .where("status", "==", "pending")
      .get();
    await Promise.all(
      pending.docs
        .filter((doc) => doc.get("channel") === "self")
        .map((doc) => doc.ref.update({ status: "cancelled" })),
    );

    const code = generateCode();
    const expiresAt = Timestamp.fromMillis(Date.now() + SELF_LINK_TTL_MS);
    await this.invites.add({
      codeHash: hashCode(code),
      grantId: null,
      memberId: null,
      careRecipientId: null,
      ownerId: ownerUid,
      channel: "self",
      email: null,
      contactKey: null,
      expiresAt,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      usedAt: null,
    });

    return {
      code,
      expiresAt: expiresAt.toDate().toISOString(),
      link: waLink(this.carehubNumber, `${ENTRY_COMMAND} ${code}`),
    };
  }

  /**
   * Mensagem "ENTRAR <código>" recebida pelo webhook. O número já foi
   * validado pela assinatura da Meta; aqui confere o código e, para membros,
   * se o número é o mesmo cadastrado pela dona.
   */
  async acceptByWhatsApp(rawCode: string, fromKey: string): Promise<WhatsAppAcceptResult> {
    if (!(await this.limiter.tryConsume("code_attempt", `wa:${fromKey}`, this.limits.codeAttemptsPerDay))) {
      return { kind: "rate_limited" };
    }

    const invite = await this.findPendingByCode(rawCode);
    if (!invite) return { kind: "invalid" };

    if (invite.channel === "self") {
      await this.linkOwnerNumber(invite.ownerId, fromKey);
      await this.markUsed(invite.id);
      return { kind: "self_linked" };
    }

    if (!invite.grantId || !invite.memberId || !invite.careRecipientId) return { kind: "invalid" };

    const member = await this.care.getMember(invite.memberId);
    const memberNumber = toWhatsAppNumber(member?.phone);
    if (!member || !memberNumber || contactKey(memberNumber) !== fromKey) {
      logger.warn("Código de convite enviado por outro número.", { from: maskPhone(fromKey) });
      return { kind: "invalid" };
    }

    const grant = await this.grants.get(invite.grantId);
    const recipientFirstName = firstName(await this.care.getCareRecipientName(invite.careRecipientId));
    if (!grant || grant.status === "revoked") return { kind: "invalid" };
    if (grant.accessLevel === "readonly") {
      // O convite continua valendo para a tela "Tenho um convite" do app.
      return { kind: "readonly", recipientFirstName };
    }

    const result = await this.grants.activate(grant.id, { contactKey: fromKey });
    if (result !== "activated") return { kind: "invalid" };

    await db.collection("whatsapp_participants").doc(fromKey).set(
      { contactKey: fromKey, updatedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
    await this.markUsed(invite.id);
    return { kind: "accepted", recipientFirstName };
  }

  /**
   * Espelha a concessão no assistido na mesma hora do aceite, sem esperar o
   * trigger `onAccessGrantWritten`. Isso garante que `accessUids`/`access`
   * já estejam gravados quando o app volta para o início e lista os perfis
   * compartilhados — senão o assistido só apareceria depois (o trigger é
   * assíncrono). O trigger continua existindo e é idempotente: reaplica o
   * mesmo estado. Uma falha aqui não derruba o aceite — o trigger cobre.
   */
  private async mirrorNow(grantId: string): Promise<void> {
    try {
      const after = await this.grants.getRaw(grantId);
      await mirrorGrant(grantId, undefined, after, this.grants);
    } catch (_) {
      logger.warn("Espelho imediato do convite falhou; o trigger vai cobrir.", {
        grantId,
      });
    }
  }

  private async linkOwnerNumber(ownerUid: string, fromKey: string): Promise<void> {
    const links = db.collection("owner_whatsapp_links");
    const previous = await links.where("uid", "==", ownerUid).get();
    const batch = db.batch();
    // Um número por conta: o vínculo anterior da mesma dona sai.
    previous.docs.filter((doc) => doc.id !== fromKey).forEach((doc) => batch.delete(doc.ref));
    batch.set(links.doc(fromKey), { uid: ownerUid, contactKey: fromKey, linkedAt: FieldValue.serverTimestamp() });
    await batch.commit();
    logger.info("WhatsApp da dona vinculado.", { to: maskPhone(fromKey) });
  }

  private async cancelPendingForMember(memberId: string): Promise<void> {
    const pending = await this.invites
      .where("memberId", "==", memberId)
      .where("status", "==", "pending")
      .get();
    await Promise.all(pending.docs.map((doc) => doc.ref.update({ status: "cancelled" })));
  }

  private async findPendingByCode(rawCode: string): Promise<InviteRecord | null> {
    const code = normalizeCode(rawCode);
    if (code.length !== CODE_LENGTH) return null;
    const query = await this.invites.where("codeHash", "==", hashCode(code)).limit(1).get();
    if (query.empty) return null;
    const invite = this.toInvite(query.docs[0].id, query.docs[0].data());
    if (invite.status !== "pending" || invite.expiresAt.toMillis() <= Date.now()) return null;
    return invite;
  }

  private async markUsed(inviteId: string): Promise<void> {
    await this.invites.doc(inviteId).update({ status: "used", usedAt: FieldValue.serverTimestamp() });
  }

  private buildShareText(input: {
    channel: Channel;
    code: string;
    memberName: string | undefined;
    ownerName: string | null;
    recipientName: string | null;
  }): string {
    const greeting = input.memberName ? `Olá, ${firstName(input.memberName)}!` : "Olá!";
    const owner = input.ownerName ? firstName(input.ownerName) : "Uma pessoa da sua família";
    const recipient = input.recipientName ? firstName(input.recipientName) : "um familiar";
    const intro = `${greeting} ${owner} convidou você para acompanhar os cuidados de ${recipient} no CareHub Plus.`;

    if (input.channel === "whatsapp") {
      const link = waLink(this.carehubNumber, `${ENTRY_COMMAND} ${input.code}`);
      return `${intro} Toque no link e envie a mensagem que vai aparecer: ${link}\nO convite vale por 48 horas.`;
    }
    return (
      `${intro} Abra o app CareHub Plus, entre na sua conta e toque em "Tenho um convite" ` +
      `para digitar o código ${input.code}. O convite vale por 48 horas.`
    );
  }

  private toInvite(id: string, data: FirebaseFirestore.DocumentData): InviteRecord {
    return {
      id,
      grantId: (data.grantId as string | null | undefined) ?? null,
      memberId: (data.memberId as string | null | undefined) ?? null,
      careRecipientId: (data.careRecipientId as string | null | undefined) ?? null,
      ownerId: (data.ownerId as string | undefined) ?? "",
      channel: (data.channel as InviteChannel | undefined) ?? "app",
      email: (data.email as string | null | undefined) ?? null,
      contactKey: (data.contactKey as string | null | undefined) ?? null,
      expiresAt: data.expiresAt as Timestamp,
      status: (data.status as InviteRecord["status"] | undefined) ?? "pending",
    };
  }
}

/** Para triggers: cancela convites pendentes de um membro removido. */
export async function cancelInvitesOfMember(memberId: string): Promise<void> {
  const pending = await db
    .collection("invites")
    .where("memberId", "==", memberId)
    .where("status", "==", "pending")
    .get();
  await Promise.all(pending.docs.map((doc) => doc.ref.update({ status: "cancelled" })));
}

export { grantIdForMember };
