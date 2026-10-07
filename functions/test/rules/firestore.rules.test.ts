/*
 * CareHub Plus — Testes / Regras do Firestore
 *
 * Prova, no Firestore Emulator, quem pode ler e gravar assistidos, tarefas,
 * chats, concessões e convites: a dona, convidados com cada nível de acesso,
 * um convite expirado e um estranho logado. Roda com `npm run test:rules`.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { after, before, beforeEach, describe, it } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  Firestore,
  getDoc,
  getDocs,
  query,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from "firebase/firestore";

// Pessoas do cenário.
const OWNER = "alice"; // dona do assistido r1
const FULL = "bia"; // Acesso Total
const READONLY = "caio"; // Apenas Visualização
const PARTIAL_TASK = "duda"; // Parcial, só tarefas
const EXPIRED = "edu"; // Acesso Total, prazo vencido
const STRANGER = "zeca"; // logado, sem relação nenhuma

const RECIPIENT = "r1";
const TASK = "t1";
const LEGACY_TASK = "t0"; // documento antigo, sem careRecipientId
const ROOM = "c1";

let env: RulesTestEnvironment;

function db(uid: string): Firestore {
  return env.authenticatedContext(uid).firestore() as unknown as Firestore;
}

function anonymous(): Firestore {
  return env.unauthenticatedContext().firestore() as unknown as Firestore;
}

async function seed(): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const admin = context.firestore() as unknown as Firestore;
    const past = Timestamp.fromMillis(Date.now() - 60 * 60 * 1000);

    await setDoc(doc(admin, "care_recipients", RECIPIENT), {
      id: RECIPIENT,
      name: "Lúcia",
      caregiverId: OWNER,
      accessUids: [FULL, READONLY, PARTIAL_TASK, EXPIRED],
      access: {
        [FULL]: { level: "full", permissions: [], expiresAt: null },
        [READONLY]: { level: "readonly", permissions: [], expiresAt: null },
        [PARTIAL_TASK]: { level: "partial", permissions: ["task", "cora"], expiresAt: null },
        [EXPIRED]: { level: "full", permissions: [], expiresAt: past },
      },
    });
    await setDoc(doc(admin, "care_recipients", "r_other"), {
      id: "r_other",
      name: "Outro",
      caregiverId: STRANGER,
    });

    await setDoc(doc(admin, "tasks", TASK), {
      id: TASK,
      caregiverId: OWNER,
      careRecipientId: RECIPIENT,
      title: "Remédio",
      isCompleted: false,
    });
    await setDoc(doc(admin, "tasks", LEGACY_TASK), {
      id: LEGACY_TASK,
      caregiverId: OWNER,
      title: "Tarefa antiga",
      isCompleted: false,
    });

    await setDoc(doc(admin, "chat_rooms", ROOM), {
      id: ROOM,
      title: "Consulta",
      careRecipientId: RECIPIENT,
      lastMessage: "Assunto criado.",
    });
    await setDoc(doc(admin, "chat_rooms", ROOM, "messages", "m1"), {
      id: "m1",
      senderId: OWNER,
      text: "Oi",
    });

    await setDoc(doc(admin, "network_members", "n1"), {
      id: "n1",
      caregiverId: OWNER,
      careRecipientId: RECIPIENT,
      name: "Bia",
      phone: "11999999999",
    });

    await setDoc(doc(admin, "access_grants", "g1"), {
      ownerId: OWNER,
      principalUid: FULL,
      careRecipientId: RECIPIENT,
      status: "active",
    });
    await setDoc(doc(admin, "invites", "i1"), {
      ownerId: OWNER,
      careRecipientId: RECIPIENT,
      status: "pending",
    });
    await setDoc(doc(admin, "assistant_sessions", "s1"), { history: [] });
  });
}

function newTask(caregiverId: string, extra: Record<string, unknown> = {}) {
  return {
    caregiverId,
    careRecipientId: RECIPIENT,
    title: "Nova tarefa",
    isCompleted: false,
    ...extra,
  };
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-carehub",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../../../firestore.rules"), "utf8"),
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

describe("care_recipients", () => {
  it("sem login ninguém lê", async () => {
    await assertFails(getDoc(doc(anonymous(), "care_recipients", RECIPIENT)));
  });

  it("a dona lê e lista os próprios assistidos", async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), "care_recipients", RECIPIENT)));
    await assertSucceeds(
      getDocs(query(collection(db(OWNER), "care_recipients"), where("caregiverId", "==", OWNER))),
    );
  });

  it("convidado ativo lê e lista os compartilhados com ele", async () => {
    await assertSucceeds(getDoc(doc(db(FULL), "care_recipients", RECIPIENT)));
    await assertSucceeds(getDoc(doc(db(READONLY), "care_recipients", RECIPIENT)));
    await assertSucceeds(
      getDocs(
        query(collection(db(FULL), "care_recipients"), where("accessUids", "array-contains", FULL)),
      ),
    );
  });

  it("convite expirado não lê o assistido", async () => {
    await assertFails(getDoc(doc(db(EXPIRED), "care_recipients", RECIPIENT)));
  });

  it("estranho não lê nem lista assistidos de outra pessoa", async () => {
    await assertFails(getDoc(doc(db(STRANGER), "care_recipients", RECIPIENT)));
    await assertFails(
      getDocs(query(collection(db(STRANGER), "care_recipients"), where("caregiverId", "==", OWNER))),
    );
    await assertFails(getDocs(collection(db(STRANGER), "care_recipients")));
  });

  it("cria assistido só em nome próprio e sem lista de acesso", async () => {
    await assertSucceeds(
      setDoc(doc(db(STRANGER), "care_recipients", "r_new"), { name: "Novo", caregiverId: STRANGER }),
    );
    await assertFails(
      setDoc(doc(db(STRANGER), "care_recipients", "r_fake"), { name: "Falso", caregiverId: OWNER }),
    );
    await assertFails(
      setDoc(doc(db(STRANGER), "care_recipients", "r_sneaky"), {
        name: "Esperto",
        caregiverId: STRANGER,
        accessUids: [OWNER],
      }),
    );
  });

  it("a dona edita, mas não mexe na lista de acesso nem troca o dono", async () => {
    await assertSucceeds(updateDoc(doc(db(OWNER), "care_recipients", RECIPIENT), { name: "Lúcia M." }));
    await assertFails(
      updateDoc(doc(db(OWNER), "care_recipients", RECIPIENT), { accessUids: [STRANGER] }),
    );
    await assertFails(
      updateDoc(doc(db(OWNER), "care_recipients", RECIPIENT), { caregiverId: STRANGER }),
    );
  });

  it("só a dona edita ou apaga o assistido", async () => {
    await assertFails(updateDoc(doc(db(FULL), "care_recipients", RECIPIENT), { name: "X" }));
    await assertFails(deleteDoc(doc(db(FULL), "care_recipients", RECIPIENT)));
    await assertFails(deleteDoc(doc(db(STRANGER), "care_recipients", RECIPIENT)));
    await assertSucceeds(deleteDoc(doc(db(OWNER), "care_recipients", RECIPIENT)));
  });
});

describe("tasks", () => {
  it("a dona lista as tarefas pelo próprio id (consulta atual do app)", async () => {
    await assertSucceeds(
      getDocs(query(collection(db(OWNER), "tasks"), where("caregiverId", "==", OWNER))),
    );
    await assertSucceeds(getDoc(doc(db(OWNER), "tasks", LEGACY_TASK)));
  });

  it("dona e convidados listam por assistido (consulta do dashboard)", async () => {
    await assertSucceeds(
      getDocs(query(collection(db(OWNER), "tasks"), where("careRecipientId", "==", RECIPIENT))),
    );
    await assertSucceeds(
      getDocs(query(collection(db(FULL), "tasks"), where("careRecipientId", "==", RECIPIENT))),
    );
    await assertSucceeds(
      getDocs(query(collection(db(READONLY), "tasks"), where("careRecipientId", "==", RECIPIENT))),
    );
  });

  it("estranho e expirado não leem tarefas", async () => {
    await assertFails(getDoc(doc(db(STRANGER), "tasks", TASK)));
    await assertFails(getDoc(doc(db(EXPIRED), "tasks", TASK)));
    await assertFails(
      getDocs(query(collection(db(STRANGER), "tasks"), where("careRecipientId", "==", RECIPIENT))),
    );
    await assertFails(getDocs(collection(db(STRANGER), "tasks")));
  });

  it("cria tarefa só com assistido e com o dono correto", async () => {
    await assertSucceeds(addDoc(collection(db(OWNER), "tasks"), newTask(OWNER)));
    await assertFails(
      addDoc(collection(db(OWNER), "tasks"), { caregiverId: OWNER, title: "Sem assistido" }),
    );
    await assertFails(addDoc(collection(db(STRANGER), "tasks"), newTask(STRANGER)));
  });

  it("convidado cria tarefa conforme o nível de acesso", async () => {
    await assertSucceeds(addDoc(collection(db(FULL), "tasks"), newTask(OWNER, { createdBy: FULL })));
    await assertSucceeds(
      addDoc(collection(db(PARTIAL_TASK), "tasks"), newTask(OWNER, { createdBy: PARTIAL_TASK })),
    );
    await assertFails(addDoc(collection(db(READONLY), "tasks"), newTask(OWNER)));
    await assertFails(addDoc(collection(db(EXPIRED), "tasks"), newTask(OWNER)));
    // A tarefa sempre pertence à dona do assistido.
    await assertFails(addDoc(collection(db(FULL), "tasks"), newTask(FULL)));
  });

  it("concluir tarefa respeita o nível e não muda o assistido", async () => {
    await assertSucceeds(updateDoc(doc(db(FULL), "tasks", TASK), { isCompleted: true }));
    await assertFails(updateDoc(doc(db(READONLY), "tasks", TASK), { isCompleted: true }));
    await assertFails(updateDoc(doc(db(FULL), "tasks", TASK), { careRecipientId: "r_other" }));
    await assertFails(updateDoc(doc(db(STRANGER), "tasks", TASK), { isCompleted: true }));
  });

  it("apagar tarefa respeita o nível", async () => {
    await assertFails(deleteDoc(doc(db(READONLY), "tasks", TASK)));
    await assertFails(deleteDoc(doc(db(STRANGER), "tasks", TASK)));
    await assertSucceeds(deleteDoc(doc(db(OWNER), "tasks", TASK)));
  });
});

describe("chat_rooms e messages", () => {
  it("dona e convidados listam as salas do assistido", async () => {
    await assertSucceeds(
      getDocs(query(collection(db(OWNER), "chat_rooms"), where("careRecipientId", "==", RECIPIENT))),
    );
    await assertSucceeds(
      getDocs(query(collection(db(FULL), "chat_rooms"), where("careRecipientId", "==", RECIPIENT))),
    );
  });

  it("estranho não lê salas, e ninguém lista sem filtro", async () => {
    await assertFails(
      getDocs(
        query(collection(db(STRANGER), "chat_rooms"), where("careRecipientId", "==", RECIPIENT)),
      ),
    );
    await assertFails(getDoc(doc(db(STRANGER), "chat_rooms", ROOM)));
    await assertFails(getDocs(collection(db(OWNER), "chat_rooms")));
  });

  it("criar sala exige permissão de chat", async () => {
    const room = { title: "Novo", careRecipientId: RECIPIENT };
    await assertSucceeds(setDoc(doc(db(OWNER), "chat_rooms", "c_owner"), room));
    await assertSucceeds(setDoc(doc(db(FULL), "chat_rooms", "c_full"), room));
    await assertFails(setDoc(doc(db(PARTIAL_TASK), "chat_rooms", "c_partial"), room));
    await assertFails(setDoc(doc(db(READONLY), "chat_rooms", "c_ro"), room));
    await assertFails(setDoc(doc(db(OWNER), "chat_rooms", "c_orphan"), { title: "Sem assistido" }));
  });

  it("mensagens: lê quem tem acesso, envia só em nome próprio", async () => {
    await assertSucceeds(getDocs(collection(db(FULL), "chat_rooms", ROOM, "messages")));
    await assertFails(getDocs(collection(db(STRANGER), "chat_rooms", ROOM, "messages")));
    await assertSucceeds(
      setDoc(doc(db(FULL), "chat_rooms", ROOM, "messages", "m2"), { senderId: FULL, text: "Oi" }),
    );
    await assertFails(
      setDoc(doc(db(FULL), "chat_rooms", ROOM, "messages", "m3"), { senderId: OWNER, text: "Oi" }),
    );
    await assertFails(
      setDoc(doc(db(READONLY), "chat_rooms", ROOM, "messages", "m4"), {
        senderId: READONLY,
        text: "Oi",
      }),
    );
    await assertFails(updateDoc(doc(db(OWNER), "chat_rooms", ROOM, "messages", "m1"), { text: "X" }));
  });

  it("atualizar a sala exige permissão de chat", async () => {
    await assertSucceeds(updateDoc(doc(db(FULL), "chat_rooms", ROOM), { lastMessage: "Oi" }));
    await assertFails(updateDoc(doc(db(READONLY), "chat_rooms", ROOM), { lastMessage: "Oi" }));
    await assertFails(updateDoc(doc(db(FULL), "chat_rooms", ROOM), { careRecipientId: "r_other" }));
  });
});

describe("network_members", () => {
  it("canal de alertas aceita só whatsapp e app", async () => {
    const base = { caregiverId: OWNER, careRecipientId: RECIPIENT, name: "Nova", phone: "11988887777" };
    await assertSucceeds(setDoc(doc(db(OWNER), "network_members", "n_ok"), base));
    await assertSucceeds(
      setDoc(doc(db(OWNER), "network_members", "n_app"), { ...base, alertChannels: ["app"] }),
    );
    await assertSucceeds(
      setDoc(doc(db(OWNER), "network_members", "n_both"), {
        ...base,
        alertChannels: ["whatsapp", "app"],
      }),
    );
    await assertFails(
      setDoc(doc(db(OWNER), "network_members", "n_sms"), { ...base, alertChannels: ["sms"] }),
    );
    await assertFails(
      setDoc(doc(db(OWNER), "network_members", "n_empty"), { ...base, alertChannels: [] }),
    );
  });

  it("a dona lista os membros pelo assistido (consulta do dashboard)", async () => {
    await assertSucceeds(
      getDocs(
        query(collection(db(OWNER), "network_members"), where("careRecipientId", "==", RECIPIENT)),
      ),
    );
  });

  it("convidado sem SOS e estranho não listam a rede pelo assistido", async () => {
    await assertFails(
      getDocs(
        query(collection(db(READONLY), "network_members"), where("careRecipientId", "==", RECIPIENT)),
      ),
    );
    await assertFails(
      getDocs(
        query(
          collection(db(STRANGER), "network_members"),
          where("careRecipientId", "==", RECIPIENT),
        ),
      ),
    );
  });

  it("estranho não lê nem cria membros na rede de outra pessoa", async () => {
    await assertFails(getDoc(doc(db(STRANGER), "network_members", "n1")));
    await assertFails(
      setDoc(doc(db(STRANGER), "network_members", "n_x"), {
        caregiverId: STRANGER,
        careRecipientId: RECIPIENT,
        name: "X",
        phone: "1",
      }),
    );
  });
});

describe("categorias de cuidado", () => {
  const category = { label: "Fisioterapia", iconKey: "activity", colorKey: "purple", isDefault: false };

  function categoryDoc(firestore: Firestore, ownerUid: string, id: string) {
    return doc(firestore, "caregivers", ownerUid, "care_categories", id);
  }

  it("cada cuidadora lê, cria e apaga só as próprias categorias", async () => {
    await assertSucceeds(setDoc(categoryDoc(db(OWNER), OWNER, "cat_1"), category));
    await assertSucceeds(getDocs(collection(db(OWNER), "caregivers", OWNER, "care_categories")));
    await assertSucceeds(deleteDoc(categoryDoc(db(OWNER), OWNER, "cat_1")));
  });

  it("padrões podem ser semeados, mas não apagados", async () => {
    await assertSucceeds(
      setDoc(categoryDoc(db(OWNER), OWNER, "health"), {
        label: "Saúde",
        iconKey: "health",
        colorKey: "green",
        isDefault: true,
      }),
    );
    await assertFails(deleteDoc(categoryDoc(db(OWNER), OWNER, "health")));
  });

  it("valida os campos da categoria", async () => {
    await assertFails(setDoc(categoryDoc(db(OWNER), OWNER, "c_empty"), { ...category, label: "" }));
    await assertFails(
      setDoc(categoryDoc(db(OWNER), OWNER, "c_long"), { ...category, label: "x".repeat(41) }),
    );
    await assertFails(
      setDoc(categoryDoc(db(OWNER), OWNER, "c_extra"), { ...category, ownerOverride: true }),
    );
  });

  it("estranho não lê nem grava categorias de outra pessoa", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        categoryDoc(context.firestore() as unknown as Firestore, OWNER, "cat_2"),
        category,
      );
    });
    await assertFails(getDoc(categoryDoc(db(STRANGER), OWNER, "cat_2")));
    await assertFails(setDoc(categoryDoc(db(STRANGER), OWNER, "cat_3"), category));
    await assertFails(deleteDoc(categoryDoc(db(STRANGER), OWNER, "cat_2")));
  });

  it("a coleção solta care_categories fica fechada", async () => {
    await assertFails(getDocs(collection(db(OWNER), "care_categories")));
    await assertFails(setDoc(doc(db(OWNER), "care_categories", "health"), category));
  });
});

describe("SOS aberto por pessoa convidada", () => {
  function alert(extra: Record<string, unknown> = {}) {
    return {
      caregiverId: OWNER,
      careRecipientId: RECIPIENT,
      notifiedMemberIds: ["n1"],
      status: "pending",
      ...extra,
    };
  }

  it("Acesso Total lê a rede do assistido e abre o SOS em nome da dona", async () => {
    await assertSucceeds(
      getDocs(query(collection(db(FULL), "network_members"), where("careRecipientId", "==", RECIPIENT))),
    );
    await assertSucceeds(setDoc(doc(db(FULL), "sos_alerts", "s_full"), alert({ requestedByUid: FULL })));
    await assertSucceeds(getDoc(doc(db(FULL), "sos_alerts", "s_full")));
    await assertSucceeds(
      updateDoc(doc(db(FULL), "sos_alerts", "s_full"), { status: "dispatched", updatedAt: "x" }),
    );
  });

  it("sem permissão de SOS não lê a rede nem abre o SOS", async () => {
    await assertFails(
      getDocs(
        query(collection(db(READONLY), "network_members"), where("careRecipientId", "==", RECIPIENT)),
      ),
    );
    await assertFails(setDoc(doc(db(READONLY), "sos_alerts", "s_ro"), alert({ requestedByUid: READONLY })));
    await assertFails(
      setDoc(doc(db(PARTIAL_TASK), "sos_alerts", "s_pt"), alert({ requestedByUid: PARTIAL_TASK })),
    );
    await assertFails(setDoc(doc(db(EXPIRED), "sos_alerts", "s_ex"), alert({ requestedByUid: EXPIRED })));
  });

  it("não dá para abrir em nome de outra dona nem fingir outro solicitante", async () => {
    await assertFails(
      setDoc(doc(db(FULL), "sos_alerts", "s_fake_owner"), alert({ caregiverId: STRANGER, requestedByUid: FULL })),
    );
    await assertFails(setDoc(doc(db(FULL), "sos_alerts", "s_no_requester"), alert()));
    await assertFails(
      setDoc(doc(db(STRANGER), "sos_alerts", "s_stranger"), alert({ requestedByUid: STRANGER })),
    );
  });

  it("a dona continua lendo e cancelando o SOS aberto pela convidada", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore() as unknown as Firestore, "sos_alerts", "s_other"),
        alert({ requestedByUid: FULL, status: "dispatched" }),
      );
    });
    await assertSucceeds(getDoc(doc(db(OWNER), "sos_alerts", "s_other")));
    await assertSucceeds(
      updateDoc(doc(db(OWNER), "sos_alerts", "s_other"), { status: "cancelled", updatedAt: "x" }),
    );
    await assertFails(getDoc(doc(db(STRANGER), "sos_alerts", "s_other")));
  });
});

describe("coleções do backend", () => {
  it("concessão: leem a dona e a própria pessoa; ninguém grava", async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), "access_grants", "g1")));
    await assertSucceeds(getDoc(doc(db(FULL), "access_grants", "g1")));
    await assertFails(getDoc(doc(db(STRANGER), "access_grants", "g1")));
    await assertFails(setDoc(doc(db(OWNER), "access_grants", "g2"), { ownerId: OWNER }));
    await assertFails(updateDoc(doc(db(FULL), "access_grants", "g1"), { status: "active" }));
  });

  it("convite: lê só a dona; ninguém grava", async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), "invites", "i1")));
    await assertFails(getDoc(doc(db(STRANGER), "invites", "i1")));
    await assertFails(setDoc(doc(db(OWNER), "invites", "i2"), { ownerId: OWNER }));
  });

  it("coleções internas ficam fechadas para o app", async () => {
    await assertFails(getDoc(doc(db(OWNER), "assistant_sessions", "s1")));
    await assertFails(setDoc(doc(db(OWNER), "ai_quota", "q1"), { count: 0 }));
    await assertFails(setDoc(doc(db(OWNER), "rate_limits", "x"), { count: 0 }));
    await assertFails(getDoc(doc(db(OWNER), "whatsapp_participants", "5511999999999")));
    await assertFails(getDoc(doc(db(OWNER), "owner_whatsapp_links", "5511999999999")));
  });
});
