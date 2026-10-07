/*
 * CareHub Plus — Functions / Limites diários
 *
 * Contadores por chave e por dia (fuso de Brasília), gravados em transação
 * para não estourar o limite quando duas mensagens chegam juntas. Usado para
 * cota do Gemini, convites, tentativas de código e pedidos de SOS. Também
 * guarda marcas "uma vez por dia" (ex.: avisar que a cota acabou).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { FieldValue } from "firebase-admin/firestore";

import { db } from "./firestore";
import { todayKey } from "./text";

export type LimitKind =
  | "ai"
  | "cora_whatsapp"
  | "invite_create"
  | "code_attempt"
  | "sos_request"
  | "notice";

export class DailyLimiter {
  /** `ai_quota` para o Gemini; `rate_limits` para o resto. */
  constructor(private readonly collection: "ai_quota" | "rate_limits" = "rate_limits") {}

  private ref(kind: LimitKind, key: string) {
    // "/" não é permitido em id de documento.
    const safeKey = key.replace(/\//g, "_");
    return db.collection(this.collection).doc(`${kind}_${safeKey}_${todayKey()}`);
  }

  /** Consome uma unidade. Devolve `false` se o limite do dia já foi atingido. */
  async tryConsume(kind: LimitKind, key: string, limit: number): Promise<boolean> {
    const ref = this.ref(kind, key);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      const count = (snapshot.get("count") as number | undefined) ?? 0;
      if (count >= limit) return false;
      tx.set(
        ref,
        { kind, count: count + 1, day: todayKey(), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return true;
    });
  }

  /**
   * Marca um evento que só deve acontecer uma vez por dia. Devolve `true`
   * apenas na primeira chamada do dia para a mesma marca.
   */
  async markOnce(kind: LimitKind, key: string, flag: string): Promise<boolean> {
    const ref = this.ref(kind, key);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      const flags = (snapshot.get("flags") as string[] | undefined) ?? [];
      if (flags.includes(flag)) return false;
      tx.set(
        ref,
        { kind, day: todayKey(), flags: [...flags, flag], updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return true;
    });
  }
}
