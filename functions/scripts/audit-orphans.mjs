/*
 * CareHub Plus — Script / Auditoria de documentos órfãos (somente leitura)
 *
 * Conta, no Firestore de produção, os documentos que as regras novas deixam
 * inacessíveis: assistidos sem `caregiverId`, tarefas sem `careRecipientId`
 * e sem `caregiverId`, e salas de chat sem `careRecipientId`. Não grava nada.
 * Mostra só contagens e ids, nunca nomes ou dados de saúde.
 *
 * Uso (na pasta functions, com credencial de administrador do projeto):
 *   gcloud auth application-default login
 *   node scripts/audit-orphans.mjs carehub-plus-21164
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const projectId = process.argv[2];
if (!projectId) {
  console.error("Informe o id do projeto: node scripts/audit-orphans.mjs <projectId>");
  process.exit(1);
}

initializeApp({ projectId });
const db = getFirestore();

const isBlank = (value) => typeof value !== "string" || value.trim() === "";

async function audit(collection, isOrphan, description) {
  // Só os dois campos de dono: nenhum dado do assistido sai do Firestore.
  const snapshot = await db.collection(collection).select("caregiverId", "careRecipientId").get();
  const ids = snapshot.docs.filter((doc) => isOrphan(doc.data())).map((doc) => doc.id);
  console.log(`${collection}: ${ids.length} de ${snapshot.size} ${description}`);
  ids.slice(0, 20).forEach((id) => console.log(`  - ${id}`));
  if (ids.length > 20) console.log(`  ... e mais ${ids.length - 20}`);
}

await audit(
  "care_recipients",
  (data) => isBlank(data.caregiverId),
  "sem caregiverId (ninguém mais consegue abrir)",
);
await audit(
  "tasks",
  (data) => isBlank(data.careRecipientId) && isBlank(data.caregiverId),
  "sem careRecipientId e sem caregiverId (ninguém mais consegue abrir)",
);
await audit(
  "tasks",
  (data) => isBlank(data.careRecipientId) && !isBlank(data.caregiverId),
  "sem careRecipientId (só a dona continua vendo)",
);
await audit(
  "chat_rooms",
  (data) => isBlank(data.careRecipientId),
  "sem careRecipientId (ninguém mais consegue abrir)",
);
