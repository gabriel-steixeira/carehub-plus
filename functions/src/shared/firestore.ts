/*
 * CareHub Plus — Functions / Firestore
 *
 * Inicializa o Firebase Admin uma única vez e expõe a instância do
 * Firestore usada pelos repositórios do backend.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();

/** Oculta o telefone nos logs, mantendo só os 4 últimos dígitos. */
export function maskPhone(phone: string): string {
  return phone.length <= 4 ? "****" : `***${phone.slice(-4)}`;
}
