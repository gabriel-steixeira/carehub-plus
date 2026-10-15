/*
 * CareHub Plus — Functions / Callable de exclusão de conta
 *
 * Função chamada pelo app (FirebaseFunctions.httpsCallable) para apagar a
 * conta do cuidador e, em cascata, tudo que pertence aos cuidados dos quais
 * ele é dono. Exige login; quem é a pessoa vem do token do Firebase Auth,
 * nunca do corpo da requisição. A exclusão da conta de autenticação é a
 * última operação e é idempotente.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { getAuth } from "firebase-admin/auth";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import { GrantRepository } from "../access/grantRepository";
import { REGION } from "../config";
import { db } from "../shared/firestore";

function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Entre na sua conta para continuar.");
  return uid;
}

/** Converte erros conhecidos e esconde os desconhecidos. */
async function run<T>(work: () => Promise<T>): Promise<T> {
  try {
    return await work();
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Não foi possível concluir agora. Tente novamente.");
  }
}

/** Apaga em massa todos os documentos de uma consulta usando o BulkWriter. */
async function deleteQuery(
  writer: FirebaseFirestore.BulkWriter,
  query: FirebaseFirestore.Query,
): Promise<void> {
  const snapshot = await query.get();
  for (const doc of snapshot.docs) {
    void writer.delete(doc.ref);
  }
}

const options = { region: REGION, maxInstances: 5 };

/**
 * Exclui a conta do cuidador autenticado.
 *
 * Como grantee (cuidador convidado), revoga as próprias concessões ativas.
 * Como dono, apaga em cascata os cuidados que criou e tudo ligado a eles
 * (tarefas, salas de chat com mensagens, rede de apoio, SOS, concessões e
 * convites). Por fim, apaga os dados do cuidador e a conta de autenticação.
 */
export const deleteAccount = onCall(options, (request) =>
  run(async () => {
    const uid = requireUid(request);
    if (request.data?.confirm === false) {
      throw new HttpsError("failed-precondition", "Confirmação necessária.");
    }

    const grants = new GrantRepository();
    let deletedRecipients = 0;
    let revokedGrantsAsOwner = 0;
    let revokedGrantsAsGrantee = 0;

    // (1) Como grantee: revoga as concessões em que esta conta é a principal.
    const asGrantee = await db
      .collection("access_grants")
      .where("principalUid", "==", uid)
      .get();
    for (const doc of asGrantee.docs) {
      if (doc.get("status") === "revoked") continue;
      const revoked = await grants.revoke(doc.id, uid);
      if (revoked) revokedGrantsAsGrantee += 1;
    }

    // (2) Como dono: apaga em cascata cada cuidado criado por esta conta.
    const recipients = await db
      .collection("care_recipients")
      .where("caregiverId", "==", uid)
      .get();

    for (const recipient of recipients.docs) {
      const rid = recipient.id;
      const writer = db.bulkWriter();

      await deleteQuery(writer, db.collection("tasks").where("careRecipientId", "==", rid));

      const chatRooms = await db
        .collection("chat_rooms")
        .where("careRecipientId", "==", rid)
        .get();
      await writer.close();
      for (const room of chatRooms.docs) {
        await db.recursiveDelete(room.ref);
      }

      const cascadeWriter = db.bulkWriter();
      await deleteQuery(
        cascadeWriter,
        db.collection("network_members").where("careRecipientId", "==", rid),
      );
      await deleteQuery(
        cascadeWriter,
        db.collection("sos_alerts").where("careRecipientId", "==", rid),
      );
      await deleteQuery(
        cascadeWriter,
        db.collection("invites").where("careRecipientId", "==", rid),
      );
      await cascadeWriter.close();

      // Revoga as concessões do cuidado antes de apagá-las (dispara o espelho).
      const recipientGrants = await db
        .collection("access_grants")
        .where("careRecipientId", "==", rid)
        .get();
      for (const doc of recipientGrants.docs) {
        if (doc.get("status") !== "revoked") {
          const revoked = await grants.revoke(doc.id, uid);
          if (revoked) revokedGrantsAsOwner += 1;
        }
      }
      const grantWriter = db.bulkWriter();
      for (const doc of recipientGrants.docs) {
        void grantWriter.delete(doc.ref);
      }
      void grantWriter.delete(recipient.ref);
      await grantWriter.close();

      deletedRecipients += 1;
    }

    // (3) Dados do próprio cuidador.
    await db.recursiveDelete(db.collection("caregivers").doc(uid));

    const caregiverWriter = db.bulkWriter();
    await deleteQuery(caregiverWriter, db.collection("push_tokens").where("uid", "==", uid));
    await deleteQuery(
      caregiverWriter,
      db.collection("owner_whatsapp_links").where("uid", "==", uid),
    );
    await deleteQuery(
      caregiverWriter,
      db.collection("notifications").where("recipientUid", "==", uid),
    );
    await caregiverWriter.close();

    // (4) Conta de autenticação por último; idempotente se já não existir.
    try {
      await getAuth().deleteUser(uid);
    } catch (error) {
      const code = (error as { code?: string }).code;
      if (code !== "auth/user-not-found") throw error;
    }

    return { ok: true, deletedRecipients, revokedGrantsAsOwner, revokedGrantsAsGrantee };
  }),
);
