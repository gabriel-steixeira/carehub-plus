/*
 * CareHub Plus — Testes / Sugestão diária da Cora
 *
 * O Gemini é trocado por um dublê que devolve respostas prontas e registra
 * o que recebeu. Assim dá para provar o cache diário (uma chamada ao modelo
 * por dia), a cota de IA e a conferência de acesso — sem gastar cota real.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { clearFirestore } from "./helpers";

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";

import { GenerateInput, TextGenerator } from "../../src/ai/geminiClient";
import { CoraAccessError } from "../../src/assistants/cora/coraBrain";
import { CoraDailySuggestion } from "../../src/assistants/cora/coraDailySuggestion";
import { db } from "../../src/shared/firestore";

const OWNER = "alice";

/** Dublê do Gemini: devolve as respostas da fila e guarda as chamadas. */
class FakeGemini implements TextGenerator {
  calls: GenerateInput[] = [];
  constructor(private readonly answers: string[] = []) {}
  async generate(input: GenerateInput): Promise<string> {
    this.calls.push(input);
    return (
      this.answers.shift() ??
      JSON.stringify({ titulo: "Oferecer água", descricao: "Idosos bebem pouca água.", categoria: "hidratação" })
    );
  }
}

/** Relógio fixo: 06/10/2026 12:00 em Brasília. */
const NOW = new Date("2026-10-06T15:00:00Z");

function suggester(fake: FakeGemini, aiDailyLimit = 60): CoraDailySuggestion {
  return new CoraDailySuggestion({ generator: fake, aiDailyLimit, now: () => NOW });
}

function request(careRecipientId = "r1") {
  return { identity: { uid: OWNER, contactKey: null }, careRecipientId };
}

beforeEach(async () => {
  await clearFirestore();
  await db.collection("care_recipients").doc("r1").set({
    id: "r1",
    name: "Lúcia",
    caregiverId: OWNER,
    type: "person",
    dateOfBirth: "1950-05-10",
  });
});

describe("CoraDailySuggestion", () => {
  it("primeira chamada do dia gera e salva no cache", async () => {
    const fake = new FakeGemini();
    const result = await suggester(fake).suggest(request());

    assert.equal(fake.calls.length, 1);
    assert.equal(result.suggestion?.id, "daily_r1_2026-10-06");
    assert.equal(result.suggestion?.category, "hidratação");

    const cached = await db.collection("care_recipients").doc("r1").collection("cora").doc("daily_suggestion").get();
    assert.equal(cached.get("date"), "2026-10-06");
    assert.equal((cached.get("suggestion") as { title: string }).title, "Oferecer água");
  });

  it("segunda chamada no mesmo dia devolve o cache sem chamar o Gemini", async () => {
    const fake = new FakeGemini();
    const cora = suggester(fake);
    await cora.suggest(request());
    const again = await cora.suggest(request());

    assert.equal(fake.calls.length, 1, "o cache não deve chamar o Gemini de novo");
    assert.equal(again.suggestion?.id, "daily_r1_2026-10-06");
  });

  it("cota de IA esgotada não chama o Gemini e devolve nulo sem cache", async () => {
    const fake = new FakeGemini();
    const result = await suggester(fake, 0).suggest(request());

    assert.equal(fake.calls.length, 0);
    assert.equal(result.suggestion, null);
  });

  it("sem acesso ao assistido lança CoraAccessError", async () => {
    await assert.rejects(
      suggester(new FakeGemini()).suggest({ identity: { uid: "zeca", contactKey: null }, careRecipientId: "r1" }),
      CoraAccessError,
    );
  });
});
