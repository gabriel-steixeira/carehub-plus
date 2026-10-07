/*
 * CareHub Plus — Functions / Assinatura do webhook
 *
 * A Meta assina cada chamada do webhook com o App Secret
 * (cabeçalho X-Hub-Signature-256). Conferir a assinatura impede que
 * qualquer pessoa que descubra a URL envie eventos falsos.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { createHmac, timingSafeEqual } from "node:crypto";

const PREFIX = "sha256=";

export function isValidSignature(
  rawBody: Buffer | undefined,
  header: string | undefined,
  appSecret: string,
): boolean {
  if (!rawBody || !header?.startsWith(PREFIX) || !appSecret) return false;

  const expected = createHmac("sha256", appSecret).update(rawBody).digest();
  const received = Buffer.from(header.slice(PREFIX.length), "hex");

  // timingSafeEqual exige tamanhos iguais e evita ataque por tempo de resposta.
  return received.length === expected.length && timingSafeEqual(received, expected);
}
