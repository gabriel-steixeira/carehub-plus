/*
 * CareHub Plus — Functions / Horário local das tarefas
 *
 * O app grava horários como texto ISO local, sem fuso
 * ("2026-10-06T18:00:00.000"), em horário de Brasília. Aqui ficam a leitura
 * do horário que o modelo propõe, a correção para nunca agendar no passado
 * e a formatação "06/10/2026 às 18:00" — as mesmas regras do app.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { APP_TIME_ZONE } from "../config";
import { localIsoNow } from "./text";

interface LocalParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
}

const pad = (value: number, size = 2) => String(value).padStart(size, "0");

function toIso(parts: LocalParts): string {
  return `${pad(parts.year, 4)}-${pad(parts.month)}-${pad(parts.day)}T${pad(parts.hour)}:${pad(parts.minute)}:00.000`;
}

function fromInstant(date: Date): LocalParts {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: APP_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (type: string) => Number(parts.find((p) => p.type === type)?.value ?? "0");
  return { year: get("year"), month: get("month"), day: get("day"), hour: get("hour"), minute: get("minute") };
}

/**
 * Lê um horário ISO. Sem fuso, é horário de Brasília (como o app grava);
 * com fuso ("Z", "-03:00"), é convertido para Brasília. `null` se inválido.
 */
export function parseLocalIso(value: string | null | undefined): string | null {
  if (!value) return null;
  const text = value.trim();

  if (/(Z|[+-]\d{2}:?\d{2})$/.test(text)) {
    const date = new Date(text);
    return Number.isNaN(date.getTime()) ? null : toIso(fromInstant(date));
  }

  const match = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?/.exec(text);
  if (!match) return null;
  const [, y, mo, d, h = "09", mi = "00"] = match;
  const parts = { year: +y, month: +mo, day: +d, hour: +h, minute: +mi };
  if (parts.month < 1 || parts.month > 12 || parts.day < 1 || parts.day > 31) return null;
  if (parts.hour > 23 || parts.minute > 59) return null;
  return toIso(parts);
}

function addDays(parts: LocalParts, days: number): LocalParts {
  const date = new Date(Date.UTC(parts.year, parts.month - 1, parts.day + days, parts.hour, parts.minute));
  return {
    year: date.getUTCFullYear(),
    month: date.getUTCMonth() + 1,
    day: date.getUTCDate(),
    hour: date.getUTCHours(),
    minute: date.getUTCMinutes(),
  };
}

function partsOf(iso: string): LocalParts {
  const [, y, mo, d, h, mi] = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(iso) ?? [];
  return { year: +y, month: +mo, day: +d, hour: +h, minute: +mi };
}

/**
 * Garante horário no futuro, preservando hora e minuto: o modelo às vezes
 * erra o ano. Se a data já passou, usa hoje; se hoje já passou, amanhã.
 */
export function ensureFutureLocalIso(proposed: string, now: Date = new Date()): string {
  const nowIso = localIsoNow(now);
  // Mesmo formato e mesmo fuso: comparar o texto equivale a comparar a data.
  if (proposed > nowIso) return proposed;

  const today = partsOf(nowIso);
  const wanted = partsOf(proposed);
  const todayAtTime = { ...today, hour: wanted.hour, minute: wanted.minute };
  const candidate = toIso(todayAtTime);
  return candidate > nowIso ? candidate : toIso(addDays(todayAtTime, 1));
}

/** "06/10/2026 às 18:00" */
export function formatLocalDateTime(iso: string): string {
  const parts = partsOf(iso);
  return `${pad(parts.day)}/${pad(parts.month)}/${parts.year} às ${pad(parts.hour)}:${pad(parts.minute)}`;
}
