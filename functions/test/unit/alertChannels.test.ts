/*
 * CareHub Plus — Testes / Canal de alertas do membro
 *
 * O canal escolhido no cadastro decide por onde chegam SOS e tarefa
 * atribuída. Campo ausente mantém o comportamento anterior (os dois).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { clearFirestore } from "./helpers";

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";

import { CareRepository, toAlertChannels, wantsAlertBy } from "../../src/repositories/careRepository";
import { db } from "../../src/shared/firestore";

beforeEach(async () => {
  await clearFirestore();
});

describe("toAlertChannels", () => {
  it("ausente, vazio ou inválido vira os dois canais", () => {
    assert.deepEqual(toAlertChannels(undefined), ["whatsapp", "app"]);
    assert.deepEqual(toAlertChannels([]), ["whatsapp", "app"]);
    assert.deepEqual(toAlertChannels(["sms"]), ["whatsapp", "app"]);
    assert.deepEqual(toAlertChannels("app"), ["whatsapp", "app"]);
  });

  it("respeita a escolha e ignora repetições", () => {
    assert.deepEqual(toAlertChannels(["app"]), ["app"]);
    assert.deepEqual(toAlertChannels(["whatsapp", "whatsapp"]), ["whatsapp"]);
    assert.deepEqual(toAlertChannels(["app", "sms", "whatsapp"]), ["app", "whatsapp"]);
  });
});

describe("CareRepository.getMember", () => {
  it("lê o canal escolhido, independente do nível de acesso", async () => {
    await db.collection("network_members").doc("m1").set({
      name: "Vizinho",
      phone: "11988887777",
      caregiverId: "alice",
      accessLevel: "readonly",
      alertChannels: ["whatsapp"],
    });
    await db.collection("network_members").doc("m2").set({ name: "Antigo", phone: "1", caregiverId: "alice" });

    const care = new CareRepository();
    const onlyWhatsApp = await care.getMember("m1");
    assert.equal(wantsAlertBy(onlyWhatsApp!, "whatsapp"), true);
    assert.equal(wantsAlertBy(onlyWhatsApp!, "app"), false);

    const legacy = await care.getMember("m2");
    assert.equal(wantsAlertBy(legacy!, "whatsapp"), true);
    assert.equal(wantsAlertBy(legacy!, "app"), true);
  });
});
