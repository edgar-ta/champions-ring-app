import {createHmac, timingSafeEqual} from "node:crypto";
import {logger} from "firebase-functions";
import {FieldValue} from "firebase-admin/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {
  LIVE_SUBSCRIPTION_STATUSES,
  MEMBERSHIPS,
  MP_ACCESS_TOKEN,
  MP_TIMEOUT_MS,
  MP_WEBHOOK_SECRET,
  REGION,
  REVERSAL_STATUSES,
  db,
} from "../core/utils/constants.js";
import {
  firstValue,
  isMembershipType,
  mercadoPagoApi,
  membershipActivation,
  timestampFromIso,
  type MercadoPagoAuthorizedPayment,
  type MercadoPagoPreapproval,
} from "../shared/utils/shared.js";

import MercadoPago, { Order } from 'mercadopago';

/**
 * Recibe y valida las notificaciones de pago de Mercado Pago.
 */
export const mercadoPagoWebhook = onRequest(
  {
    region: REGION,
    // Mercado Pago llama sin credenciales de Google; la seguridad la
    // da la firma x-signature.
    invoker: "public",
    secrets: [MP_ACCESS_TOKEN, MP_WEBHOOK_SECRET],
  },
  async (req, res) => {
    
  }
);
