/*
 * CareHub Plus — Functions / Formatação de texto
 *
 * Utilitários para montar os parâmetros das mensagens: a Meta rejeita
 * parâmetros com quebra de linha, tabulação ou espaços repetidos, e os
 * horários do app chegam como texto ISO sem fuso.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { APP_TIME_ZONE } from "../config";

/** Limpa um valor para caber nas regras de parâmetro de template da Meta. */
export function templateParam(value: string | null | undefined, maxLength = 60): string {
  const clean = (value ?? "")
    .replace(/[\r\n\t]+/g, " ")
    .replace(/ {2,}/g, " ")
    .trim();
  if (!clean) return "-";
  return clean.length > maxLength ? `${clean.slice(0, maxLength - 1)}…` : clean;
}

/** Primeiro nome, para a mensagem soar pessoal sem expor o nome completo. */
export function firstName(fullName: string | null | undefined): string {
  return templateParam(fullName).split(" ")[0];
}

/**
 * Formata `scheduledTime` como "28/09 às 14:30".
 *
 * O app grava `DateTime.toIso8601String()` em horário local, sem fuso
 * ("2026-09-28T14:30:00.000"). Esse texto é lido como está; só valores com
 * fuso explícito (ex.: terminados em "Z") são convertidos para Brasília.
 */
export function formatScheduledTime(iso: string | null | undefined): string {
  if (!iso) return "-";

  const hasTimeZone = /(Z|[+-]\d{2}:?\d{2})$/.test(iso);
  if (hasTimeZone) {
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return "-";
    const parts = new Intl.DateTimeFormat("pt-BR", {
      timeZone: APP_TIME_ZONE,
      day: "2-digit",
      month: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    }).formatToParts(date);
    const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
    return `${get("day")}/${get("month")} às ${get("hour")}:${get("minute")}`;
  }

  const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(iso);
  if (!match) return "-";
  const [, , month, day, hour, minute] = match;
  return `${day}/${month} às ${hour}:${minute}`;
}

/**
 * Agora, em horário de Brasília e no mesmo formato que o app grava
 * ("2026-09-28T14:30:05.123", sem fuso). Mantém ordenação e exibição
 * consistentes com os documentos criados pelo Flutter.
 */
export function localIsoNow(now = new Date()): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: APP_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "00";
  const millis = String(now.getMilliseconds()).padStart(3, "0");
  return `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}:${get("second")}.${millis}`;
}

/** Data de hoje em Brasília no formato AAAAMMDD (chave da cota diária). */
export function todayKey(now = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: APP_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })
    .format(now)
    .replace(/-/g, "");
}
