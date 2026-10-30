/*
 * CareHub Plus — Functions / Notificações do app
 *
 * Avisa um membro da rede de apoio dentro do CareHub, em dois canais:
 * grava em `notifications/{id}` (sino e lista do app, em tempo real) e envia
 * um push pelo Firebase Cloud Messaging para os aparelhos da conta dele
 * (aviso com o app fechado). O membro é ligado à conta pelo e-mail
 * cadastrado na Rede de Apoio; sem conta correspondente, nada é enviado.
 *
 * Respeita as preferências do destinatário em
 * `caregivers/{uid}.notificationPreferences`.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";

import { GrantRepository } from "../access/grantRepository";
import { MemberContact } from "../repositories/careRepository";
import { db } from "../shared/firestore";

export type AppNotificationType = "sos" | "task" | "chat";

/** Preferência que liga ou desliga cada tipo (mesmas chaves do app). */
const PREFERENCE_BY_TYPE: Record<AppNotificationType, string> = {
  sos: "sosAlerts",
  task: "createdTasks",
  chat: "newChats",
};

const PUSH_PREFERENCE = "pushNotifications";

/** Tokens que o FCM informa como mortos e devem ser apagados. */
const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

export interface AppNotificationInput {
  type: AppNotificationType;
  title: string;
  body: string;
  /** Id da tarefa, da sala de chat ou do alerta de SOS. */
  relatedId: string;
  /** Cuidador que originou o aviso. */
  caregiverId: string;
  careRecipientId: string | null;
}

export class AppNotifier {
  private readonly notifications = db.collection("notifications");
  private readonly pushTokens = db.collection("push_tokens");

  constructor(private readonly grants: GrantRepository = new GrantRepository()) {}

  /** Notifica o membro, se ele tiver conta no app. Nunca lança erro. */
  async notifyMember(member: MemberContact, input: AppNotificationInput): Promise<void> {
    try {
      const uid = await this.resolveUid(member);
      if (!uid) {
        logger.info("Membro sem conta no app: notificação não criada.", {
          memberId: member.id,
          type: input.type,
        });
        return;
      }
      await this.deliver(uid, member.id, input);
    } catch (error) {
      // Notificação é complemento: uma falha aqui não pode impedir o
      // WhatsApp nem derrubar o trigger.
      logger.error("Falha ao criar notificação do app.", {
        memberId: member.id,
        type: input.type,
        reason: error instanceof Error ? error.message : String(error),
      });
    }
  }

  /** Notifica uma conta conhecida (ex.: a dona do assistido). Nunca lança erro. */
  async notifyUid(uid: string, input: AppNotificationInput): Promise<void> {
    try {
      await this.deliver(uid, null, input);
    } catch (error) {
      logger.error("Falha ao criar notificação do app.", {
        type: input.type,
        reason: error instanceof Error ? error.message : String(error),
      });
    }
  }

  private async deliver(uid: string, memberId: string | null, input: AppNotificationInput): Promise<void> {
    const preferences = await this.fetchPreferences(uid);
    if (preferences[PREFERENCE_BY_TYPE[input.type]] === false) return;

    const ref = this.notifications.doc();
    await ref.set({
      id: ref.id,
      recipientUid: uid,
      memberId,
      ...input,
      createdAt: FieldValue.serverTimestamp(),
      readAt: null,
    });

    if (preferences[PUSH_PREFERENCE] !== false) {
      await this.sendPush(uid, ref.id, input);
    }
  }

  /**
   * Descobre a conta do membro. A fonte da verdade é a concessão de acesso:
   * ao aceitar o convite, o `uid` da conta fica em `access_grants.principalUid`.
   * O e-mail é só um complemento, para membros convidados por e-mail que ainda
   * não têm concessão ligada a uma conta. Sem nenhum dos dois, não há como
   * notificar pelo app.
   */
  private async resolveUid(member: MemberContact): Promise<string | null> {
    const grant = await this.grants.getByMember(member.id);
    if (grant?.principalUid) return grant.principalUid;
    return this.resolveUidByEmail(member);
  }

  private async resolveUidByEmail(member: MemberContact): Promise<string | null> {
    if (!member.email) return null;
    try {
      const user = await getAuth().getUserByEmail(member.email.toLowerCase());
      return user.uid;
    } catch (error) {
      if ((error as { code?: string })?.code === "auth/user-not-found") return null;
      throw error;
    }
  }

  private async fetchPreferences(uid: string): Promise<Record<string, unknown>> {
    const snapshot = await db.collection("caregivers").doc(uid).get();
    const raw = snapshot.get("notificationPreferences");
    return raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
  }

  private async sendPush(
    uid: string,
    notificationId: string,
    input: AppNotificationInput,
  ): Promise<void> {
    const snapshot = await this.pushTokens.where("uid", "==", uid).get();
    const tokens = snapshot.docs.map((doc) => doc.id);
    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: input.title, body: input.body },
      data: {
        notificationId,
        type: input.type,
        relatedId: input.relatedId,
      },
      android: {
        // SOS fura o modo de economia de bateria; o resto segue o normal.
        priority: input.type === "sos" ? "high" : "normal",
      },
    });

    const deadTokens = response.responses
      .map((result, index) =>
        !result.success && INVALID_TOKEN_CODES.has(result.error?.code ?? "") ? tokens[index] : null,
      )
      .filter((token): token is string => token !== null);

    await Promise.all(deadTokens.map((token) => this.pushTokens.doc(token).delete()));

    logger.info("Push enviado.", {
      type: input.type,
      success: response.successCount,
      failure: response.failureCount,
      removedTokens: deadTokens.length,
    });
  }
}
