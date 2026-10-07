/*
 * CareHub Plus — Functions / Configuração
 *
 * Centraliza região, segredos e parâmetros da integração com a WhatsApp
 * Cloud API. Segredos ficam no Secret Manager (nunca no código nem no app);
 * parâmetros comuns ficam no arquivo .env.<projectId> da pasta functions.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { defineInt, defineSecret, defineString } from "firebase-functions/params";

/** Mesma região do Firestore (southamerica-east1), exigida pelos triggers. */
export const REGION = "southamerica-east1";

/** Token permanente do System User da Meta (Bearer das chamadas à API). */
export const whatsappToken = defineSecret("WHATSAPP_TOKEN");

/** App Secret do app da Meta, usado para validar a assinatura do webhook. */
export const whatsappAppSecret = defineSecret("WHATSAPP_APP_SECRET");

/** Texto livre escolhido por você e repetido no painel da Meta. */
export const whatsappVerifyToken = defineSecret("WHATSAPP_VERIFY_TOKEN");

/** Id do número de telefone cadastrado na Cloud API. */
export const whatsappPhoneNumberId = defineString("WHATSAPP_PHONE_NUMBER_ID");

/** Versão da Graph API. */
export const whatsappGraphVersion = defineString("WHATSAPP_GRAPH_VERSION", {
  default: "v23.0",
});

/** Teto de mensagens por cuidador por dia — protege contra custo inesperado. */
export const whatsappDailyLimit = defineInt("WHATSAPP_DAILY_LIMIT_PER_CAREGIVER", {
  default: 30,
});

/** Janela de atendimento da Meta: texto livre só é aceito dentro dela. */
export const CUSTOMER_SERVICE_WINDOW_MS = 24 * 60 * 60 * 1000;

/** Fuso usado para formatar horários e contar a cota diária. */
export const APP_TIME_ZONE = "America/Sao_Paulo";

/**
 * Número do WhatsApp do CareHub em formato internacional, só dígitos
 * (ex.: 5511999999999). Monta o link `wa.me` dos convites.
 */
export const whatsappDisplayNumber = defineString("WHATSAPP_DISPLAY_NUMBER", {
  default: "",
});

// ---------------------------------------------------------------------------
// Assistentes (Cora e Toke)
// ---------------------------------------------------------------------------

/** Chave do Google AI Studio. Só existe no backend, nunca no app. */
export const geminiApiKey = defineSecret("GEMINI_API_KEY");

/** Modelo do Gemini (o mesmo que o app usava). */
export const geminiModel = defineString("GEMINI_MODEL", {
  default: "gemini-3.5-flash-lite",
});

/** Chamadas ao Gemini por pessoa por dia, somando app e WhatsApp. */
export const aiDailyLimit = defineInt("AI_DAILY_LIMIT_PER_PERSON", { default: 60 });

/** Respostas da Cora pelo WhatsApp por pessoa por dia. */
export const coraWhatsappDailyLimit = defineInt("CORA_WHATSAPP_DAILY_LIMIT", {
  default: 40,
});

// ---------------------------------------------------------------------------
// SOS, convites e tentativas
// ---------------------------------------------------------------------------

/** Avisos de SOS por cuidador por dia — cota própria, separada da Cora. */
export const sosDailyLimit = defineInt("SOS_DAILY_LIMIT_PER_CAREGIVER", { default: 50 });

/** Pedidos de SOS abertos pela Cora por pessoa por dia. */
export const sosRequestsDailyLimit = defineInt("SOS_REQUESTS_DAILY_LIMIT_PER_PERSON", {
  default: 5,
});

/** Convites criados por dona por dia. */
export const inviteDailyLimit = defineInt("INVITE_DAILY_LIMIT", { default: 20 });

/** Tentativas de código de convite por conta ou número por dia. */
export const codeAttemptsDailyLimit = defineInt("CODE_ATTEMPTS_DAILY_LIMIT", { default: 5 });

/** Validade do convite enviado à rede de apoio. */
export const INVITE_TTL_MS = 48 * 60 * 60 * 1000;

/** Validade do código que a dona usa para ligar o próprio WhatsApp. */
export const SELF_LINK_TTL_MS = 10 * 60 * 1000;
