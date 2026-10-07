/*
 * CareHub Plus — Functions / Repositório de dados de cuidado
 *
 * Lê e grava as coleções que o app já usa (network_members, tasks,
 * care_recipients, caregivers, sos_alerts, chat_rooms). Mantém o mesmo
 * formato dos models do Flutter para que o app leia o que o backend grava.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { localIsoNow } from "../shared/text";
import { db } from "../shared/firestore";

/** Dados do membro da rede necessários para enviar mensagem. */
export interface MemberContact {
  id: string;
  name: string;
  phone: string;
  /** E-mail cadastrado na Rede de Apoio — liga o membro à conta dele no app. */
  email: string | null;
  caregiverId: string | null;
  careRecipientId: string | null;
  /** Por onde o membro recebe SOS e tarefa atribuída (escolha da dona). */
  alertChannels: AlertChannel[];
}

export type AlertChannel = "whatsapp" | "app";

/** Campo ausente, vazio ou inválido = os dois canais (comportamento anterior). */
export function toAlertChannels(value: unknown): AlertChannel[] {
  const valid = Array.isArray(value)
    ? value.filter((item): item is AlertChannel => item === "whatsapp" || item === "app")
    : [];
  return valid.length > 0 ? [...new Set(valid)] : ["whatsapp", "app"];
}

export function wantsAlertBy(member: MemberContact, channel: AlertChannel): boolean {
  return member.alertChannels.includes(channel);
}

export type AssignmentResponse = "accepted" | "declined";

export type SosResponseResult =
  | "accepted_first"
  | "already_accepted"
  | "declined"
  | "not_allowed";

export class CareRepository {
  async getMember(memberId: string): Promise<MemberContact | null> {
    const snapshot = await db.collection("network_members").doc(memberId).get();
    return snapshot.exists ? this.toMember(snapshot.id, snapshot.data() ?? {}) : null;
  }

  async getMembers(memberIds: string[]): Promise<MemberContact[]> {
    if (memberIds.length === 0) return [];
    const refs = memberIds.map((id) => db.collection("network_members").doc(id));
    const snapshots = await db.getAll(...refs);
    return snapshots
      .filter((s) => s.exists)
      .map((s) => this.toMember(s.id, s.data() ?? {}));
  }

  async getCareRecipientName(careRecipientId: string | null | undefined): Promise<string | null> {
    if (!careRecipientId) return null;
    const snapshot = await db.collection("care_recipients").doc(careRecipientId).get();
    return (snapshot.get("name") as string | undefined) ?? null;
  }

  /** Cuidador dono do perfil cuidado — usado quando o documento não o grava. */
  async getCareRecipientOwnerId(careRecipientId: string | null | undefined): Promise<string | null> {
    if (!careRecipientId) return null;
    const snapshot = await db.collection("care_recipients").doc(careRecipientId).get();
    return (snapshot.get("caregiverId") as string | undefined) ?? null;
  }

  async getCaregiverName(caregiverId: string | null | undefined): Promise<string | null> {
    if (!caregiverId) return null;
    const snapshot = await db.collection("caregivers").doc(caregiverId).get();
    return (snapshot.get("name") as string | undefined) ?? null;
  }

  /**
   * Registra o aceite ou a recusa da tarefa pelo membro. Só vale para o
   * membro a quem a tarefa foi atribuída.
   */
  async setTaskAssignmentResponse(
    taskId: string,
    memberId: string,
    response: AssignmentResponse,
  ): Promise<boolean> {
    const ref = db.collection("tasks").doc(taskId);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists || snapshot.get("assignedToMemberId") !== memberId) {
        return false;
      }
      tx.update(ref, {
        assignmentStatus: response,
        assignmentRespondedAt: localIsoNow(),
      });
      return true;
    });
  }

  /**
   * Registra a resposta ao SOS. O primeiro "Estou indo" vira o aceite do
   * alerta; os seguintes ficam só no histórico de respostas.
   */
  async registerSosResponse(
    alertId: string,
    memberId: string,
    accepted: boolean,
  ): Promise<SosResponseResult> {
    const ref = db.collection("sos_alerts").doc(alertId);
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      const notified = (snapshot.get("notifiedMemberIds") as string[] | undefined) ?? [];
      if (!snapshot.exists || !notified.includes(memberId)) return "not_allowed";

      const update: Record<string, unknown> = {
        [`responses.${memberId}`]: accepted ? "accepted" : "declined",
        updatedAt: localIsoNow(),
      };

      if (!accepted) {
        tx.update(ref, update);
        return "declined";
      }

      if (snapshot.get("status") !== "dispatched") {
        tx.update(ref, update);
        return "already_accepted";
      }

      tx.update(ref, {
        ...update,
        status: "accepted",
        acceptedByMemberId: memberId,
        acceptedAt: localIsoNow(),
      });
      return "accepted_first";
    });
  }

  /** Grava o resumo do envio no alerta, para o app mostrar quem foi avisado. */
  async saveSosDispatchSummary(alertId: string, sent: number, failed: number): Promise<void> {
    await db.collection("sos_alerts").doc(alertId).update({
      whatsappSummary: { sent, failed, at: localIsoNow() },
    });
  }

  private toMember(id: string, data: FirebaseFirestore.DocumentData): MemberContact {
    return {
      id,
      name: (data.name as string | undefined) ?? "",
      phone: (data.phone as string | undefined) ?? "",
      email: ((data.email as string | undefined) ?? "").trim() || null,
      caregiverId: (data.caregiverId as string | undefined) ?? null,
      careRecipientId: (data.careRecipientId as string | undefined) ?? null,
      alertChannels: toAlertChannels(data.alertChannels),
    };
  }
}
