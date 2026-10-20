/*
 * CareHub Plus — Functions / Ponto de entrada
 *
 * Exporta as Cloud Functions da integração com o WhatsApp e das
 * notificações do app. O Firebase publica cada export como uma função
 * separada.
 *
 * Author: Vitoria Lana
 * Created on: 28/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import { setGlobalOptions } from "firebase-functions/v2";

import { REGION } from "./config";

// Limita instâncias simultâneas: protege contra custo em caso de abuso.
setGlobalOptions({ region: REGION, maxInstances: 5 });

export { onTaskAssigned } from "./triggers/onTaskAssigned";
export { onSosAlertDispatched } from "./triggers/onSosAlertDispatched";
export { onChatRoomCreated } from "./triggers/onChatRoomCreated";
export { whatsappWebhook } from "./webhook/whatsappWebhook";
export {
  cleanupExpiredAccess,
  onAccessGrantWritten,
  onNetworkMemberWritten,
} from "./triggers/accessTriggers";
export {
  cancelInvite,
  claimPendingInvites,
  createInvite,
  createSelfLinkCode,
  redeemInviteCode,
  revokeAccess,
} from "./callable/invites";
export { coraChat, coraDailySuggestion, tokeInterpret } from "./callable/assistants";
export { deleteAccount } from "./callable/account";
export { acceptSosAlert, declineSosAlert, getSosAlertDetail } from "./callable/sos";
