/*
 * CareHub Plus — Testes / Utilitários dos testes unitários
 *
 * Aponta o Admin SDK para o Firestore Emulator (iniciado pelo
 * `firebase emulators:exec`) e oferece limpeza do banco entre os testes.
 * Importe este arquivo antes de qualquer módulo de `src/`.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

export const TEST_PROJECT = "demo-carehub";

process.env.GCLOUD_PROJECT ??= TEST_PROJECT;
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

/** Apaga todos os documentos do emulador. */
export async function clearFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const response = await fetch(
    `http://${host}/emulator/v1/projects/${TEST_PROJECT}/databases/(default)/documents`,
    { method: "DELETE" },
  );
  if (!response.ok) {
    throw new Error(`Falha ao limpar o emulador (HTTP ${response.status}).`);
  }
}
