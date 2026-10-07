/*
 * CareHub Plus — Functions / Normalização de telefone
 *
 * O app grava o telefone do membro como texto livre ("(11) 98765-4321",
 * "11987654321", "+55 11 ..."). A Cloud API exige só dígitos com código do
 * país. Aqui ficam a conversão e a chave canônica que trata o nono dígito
 * dos celulares brasileiros (a Meta às vezes devolve o número sem ele).
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

const BRAZIL_CODE = "55";

/**
 * Converte o telefone digitado no app para o formato aceito pela API
 * (ex.: "5511987654321"). Devolve `null` quando não é um número válido.
 */
export function toWhatsAppNumber(raw: string | null | undefined): string | null {
  if (!raw) return null;

  let digits = raw.replace(/\D/g, "");
  if (digits.startsWith("00")) {
    digits = digits.slice(2); // prefixo internacional "00"
  } else if (digits.startsWith("0")) {
    digits = digits.slice(1); // prefixo de operadora/tronco "0"
  }

  // Número nacional sem código do país: DDD + 8 ou 9 dígitos.
  if (digits.length === 10 || digits.length === 11) {
    digits = BRAZIL_CODE + digits;
  }

  if (digits.length < 12 || digits.length > 15) return null;
  return digits;
}

/**
 * Chave única por pessoa: celulares brasileiros com e sem o nono dígito
 * viram o mesmo valor, para casar envio e resposta.
 */
export function contactKey(whatsAppNumber: string): string {
  const isBrazilWithoutNinthDigit =
    whatsAppNumber.startsWith(BRAZIL_CODE) && whatsAppNumber.length === 12;
  if (!isBrazilWithoutNinthDigit) return whatsAppNumber;

  const areaCode = whatsAppNumber.slice(2, 4);
  const local = whatsAppNumber.slice(4);
  const isMobile = /^[6-9]/.test(local);
  return isMobile ? `${BRAZIL_CODE}${areaCode}9${local}` : whatsAppNumber;
}
