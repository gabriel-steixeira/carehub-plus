/*
 * CareHub Plus — Functions / Repositório do histórico de WhatsApp
 *
 * Guarda o que entrou e saiu pelo WhatsApp (whatsapp_messages), o contexto
 * da última conversa com cada número (whatsapp_contacts), a cota diária por
 * cuidador (whatsapp_quota) e as travas que impedem envio duplicado
 * (whatsapp_dispatch_locks). Nenhuma dessas coleções é gravada pelo app.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { FieldValue, Timestamp } from "firebase-admin/firestore";

import { db } from "../shared/firestore";
import { todayKey } from "../shared/text";

export type RelatedType = "task" | "sos" | "chat" | "cora";

/** A quem e a que assunto uma mensagem se refere. */
export interface ConversationContext {
  memberId: string;
  memberName: string;
  caregiverId: string;
  careRecipientId: string | null;
  relatedType: RelatedType;
  relatedId: string;
}

export interface ContactRecord extends Partial<ConversationContext> {
  lastInboundAt?: Timestamp;
}

/** Cada balde tem a própria cota diária. */
export type QuotaBucket = "network" | "sos" | "cora";

const ALREADY_EXISTS = 6; // código gRPC do Firestore

function isAlreadyExists(error: unknown): boolean {
  return (error as { code?: number })?.code === ALREADY_EXISTS;
}

export class MessageLogRepository {
  private readonly messages = db.collection("whatsapp_messages");
  private readonly contacts = db.collection("whatsapp_contacts");

  /**
   * Garante que um evento só dispare envio uma vez. Os triggers do Firebase
   * podem rodar mais de uma vez para o mesmo evento.
   */
  async acquireDispatchLock(key: string): Promise<boolean> {
    try {
      await db.collection("whatsapp_dispatch_locks").doc(key).create({
        createdAt: FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      if (isAlreadyExists(error)) return false;
      throw error;
    }
  }

  /**
   * Reserva uma mensagem na cota diária de um balde. `network` mantém o id
   * antigo (`<caregiverId>_<dia>`); `sos` e `cora` têm contadores próprios,
   * para que conversar com a Cora nunca impeça um SOS.
   */
  async reserveQuota(bucket: QuotaBucket, key: string, limit: number): Promise<boolean> {
    const prefix = bucket === "network" ? "" : `${bucket}_`;
    const ref = db.collection("whatsapp_quota").doc(`${prefix}${key.replace(/\//g, "_")}_${todayKey()}`);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      const count = (snapshot.get("count") as number | undefined) ?? 0;
      if (count >= limit) return false;
      tx.set(ref, { bucket, key, count: count + 1, day: todayKey() }, { merge: true });
      return true;
    });
  }

  async logOutbound(
    wamid: string,
    to: string,
    key: string,
    context: ConversationContext,
    kind: "template" | "text" | "interactive",
    templateName: string | null,
  ): Promise<void> {
    const batch = db.batch();
    batch.set(this.messages.doc(wamid), {
      direction: "outbound",
      kind,
      templateName,
      to,
      contactKey: key,
      ...context,
      status: "accepted",
      createdAt: FieldValue.serverTimestamp(),
    });
    batch.set(
      this.contacts.doc(key),
      { ...context, lastOutboundAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
    await batch.commit();
  }

  async logOutboundFailure(
    to: string,
    context: ConversationContext,
    reason: string,
    errorCode: number | null,
  ): Promise<void> {
    await this.messages.add({
      direction: "outbound",
      to,
      ...context,
      status: "failed",
      errorMessage: reason,
      errorCode,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  /** Atualiza o status (sent, delivered, read, failed) enviado pela Meta. */
  async updateDeliveryStatus(
    wamid: string,
    status: string,
    errorCode: number | null,
    errorMessage: string | null,
  ): Promise<void> {
    try {
      await this.messages.doc(wamid).update({
        status,
        errorCode,
        errorMessage,
        [`statusHistory.${status}`]: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Status de mensagem que não foi enviada por este backend: ignora.
      if ((error as { code?: number })?.code !== 5) throw error;
    }
  }

  /**
   * Salva a mensagem recebida. Devolve `false` se ela já tinha chegado.
   *
   * O texto livre não é guardado (só o tipo e o tamanho): desde que a ponte
   * com o chat saiu, o backend não precisa dele, e conversas com a Cora podem
   * ter dados de saúde. Respostas de botão continuam registradas.
   */
  async saveInboundIfNew(
    wamid: string,
    from: string,
    key: string,
    text: string,
    buttonPayload: string | null,
    context: ContactRecord | null,
  ): Promise<boolean> {
    try {
      await this.messages.doc(wamid).create({
        direction: "inbound",
        from,
        contactKey: key,
        text: buttonPayload ? text : null,
        textLength: text.length,
        buttonPayload,
        memberId: context?.memberId ?? null,
        caregiverId: context?.caregiverId ?? null,
        careRecipientId: context?.careRecipientId ?? null,
        createdAt: FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      if (isAlreadyExists(error)) return false;
      throw error;
    }
  }

  async getContact(key: string): Promise<ContactRecord | null> {
    const snapshot = await this.contacts.doc(key).get();
    return snapshot.exists ? (snapshot.data() as ContactRecord) : null;
  }

  /** Marca que o número respondeu: abre a janela de 24h da Meta. */
  async touchInbound(key: string): Promise<void> {
    await this.contacts.doc(key).set(
      { lastInboundAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
}
