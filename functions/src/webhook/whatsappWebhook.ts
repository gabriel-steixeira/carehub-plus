/*
 * CareHub Plus — Functions / Webhook do WhatsApp
 *
 * Endpoint HTTPS que a Meta chama a cada mensagem recebida ou mudança de
 * status. GET faz a verificação inicial do painel da Meta; POST valida a
 * assinatura e entrega cada evento ao porteiro (InboundRouter), que decide
 * entre botões da rede, aceite de convite, Cora ou silêncio.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import * as logger from "firebase-functions/logger";
import { onRequest } from "firebase-functions/v2/https";

import { InviteService } from "../access/inviteService";
import { GeminiClient } from "../ai/geminiClient";
import { CoraBrain } from "../assistants/cora/coraBrain";
import {
  aiDailyLimit,
  codeAttemptsDailyLimit,
  geminiApiKey,
  geminiModel,
  inviteDailyLimit,
  REGION,
  sosRequestsDailyLimit,
  whatsappAppSecret,
  whatsappDisplayNumber,
  whatsappToken,
  whatsappVerifyToken,
} from "../config";
import { CoraWhatsAppChannel } from "../whatsapp/coraWhatsAppChannel";
import { SosConversation } from "../whatsapp/sosConversation";
import { createMessenger } from "../whatsapp/whatsappMessenger";
import { IncomingMessage, IncomingStatus, InboundRouter } from "./inboundRouter";
import { isValidSignature } from "./signature";

interface WebhookBody {
  object?: string;
  entry?: {
    changes?: {
      field?: string;
      value?: { messages?: IncomingMessage[]; statuses?: IncomingStatus[] };
    }[];
  }[];
}

function createRouter(): InboundRouter {
  const messenger = createMessenger();
  const brain = new CoraBrain({
    generator: new GeminiClient({ apiKey: geminiApiKey.value(), model: geminiModel.value() }),
    aiDailyLimit: aiDailyLimit.value(),
  });
  return new InboundRouter({
    messenger,
    cora: new CoraWhatsAppChannel(brain, new SosConversation(sosRequestsDailyLimit.value()), messenger),
    invites: new InviteService(whatsappDisplayNumber.value(), {
      invitesPerDay: inviteDailyLimit.value(),
      codeAttemptsPerDay: codeAttemptsDailyLimit.value(),
    }),
  });
}

export const whatsappWebhook = onRequest(
  {
    region: REGION,
    secrets: [whatsappToken, whatsappAppSecret, whatsappVerifyToken, geminiApiKey],
    maxInstances: 3,
    timeoutSeconds: 120,
  },
  async (req, res) => {
    if (req.method === "GET") {
      const isSubscribe = req.query["hub.mode"] === "subscribe";
      const tokenMatches = req.query["hub.verify_token"] === whatsappVerifyToken.value();
      if (isSubscribe && tokenMatches) {
        res.status(200).send(String(req.query["hub.challenge"] ?? ""));
      } else {
        res.sendStatus(403);
      }
      return;
    }

    if (req.method !== "POST") {
      res.sendStatus(405);
      return;
    }

    // Antes de qualquer outra coisa: só a Meta, assinando com o App Secret.
    const signature = req.get("x-hub-signature-256");
    if (!isValidSignature(req.rawBody, signature, whatsappAppSecret.value())) {
      logger.warn("Webhook com assinatura inválida rejeitado.");
      res.sendStatus(401);
      return;
    }

    const body = req.body as WebhookBody;
    if (body.object !== "whatsapp_business_account") {
      res.sendStatus(404);
      return;
    }

    const router = createRouter();
    for (const entry of body.entry ?? []) {
      for (const change of entry.changes ?? []) {
        if (change.field !== "messages" || !change.value) continue;

        for (const status of change.value.statuses ?? []) {
          await router.safely(() => router.handleStatus(status));
        }
        for (const message of change.value.messages ?? []) {
          await router.safely(() => router.handleMessage(message));
        }
      }
    }

    // Sempre 200 depois de validar: a Meta reenvia em caso de erro e as
    // gravações já são idempotentes (id da mensagem como id do documento).
    res.sendStatus(200);
  },
);
