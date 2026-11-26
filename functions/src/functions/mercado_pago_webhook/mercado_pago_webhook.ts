import {createHmac, timingSafeEqual} from "node:crypto";
import {logger} from "firebase-functions";
import type {Request} from "express";
import {onRequest} from "firebase-functions/v2/https";
import {
  MP_ACCESS_TOKEN_V2,
  MP_WEBHOOK_SECRET_V2,
  REGION,
} from "../../core/utils/constants.js";
import type {
  MercadoPagoOrder,
  OrderHandler,
} from "../../shared/models/register_order.js";
import {recuperarOrder} from "../../shared/utils/register_order.js";
import {asRecord, firstValue} from "../../shared/utils/shared.js";
import {handlerOrderAprobada} from "./handler_order_aprobada.js";
import {handlerOrderCancelada} from "./handler_order_cancelada.js";
import {handlerOrderPendiente} from "./handler_order_pendiente.js";
import {handlerOrderRechazada} from "./handler_order_rechazada.js";
import {handlerOrderReembolsada} from "./handler_order_reembolsada.js";

interface MercadoPagoNotification {
  type?: unknown;
  data?: unknown;
  external_reference?: unknown;
}

/**
 * Recibe y valida las notificaciones de pago de Mercado Pago.
 */
export const mercadoPagoWebhook = onRequest(
  {
    region: REGION,
    invoker: "public",
    secrets: [MP_ACCESS_TOKEN_V2, MP_WEBHOOK_SECRET_V2],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST").status(405).send();
      return;
    }

    const notification = asRecord(req.body) as MercadoPagoNotification | null;
    const notificationData = asRecord(notification?.data);
    const notificationType =
      firstValue(notification?.type) ?? firstValue(req.query.type);
    if (notificationType !== "order") {
      res.status(501).send();
      return;
    }

    const orderId =
      firstValue(notificationData?.id) ??
      firstValue(req.query["data.id"]);
    if (!orderId) {
      res.status(400).send();
      return;
    }
    if (!validarFirma(req, orderId)) {
      logger.warn("Firma no válida en notificación de Mercado Pago.");
      res.status(401).send();
      return;
    }

    try {
      const order = await recuperarOrder(orderId);
      if (!order.external_reference) {
        throw new Error(
          "La order recuperada no incluye external_reference.",
        );
      }

      const notifiedExternalReference =
        firstValue(notification?.external_reference) ??
        firstValue(notificationData?.external_reference);
      if (
        notifiedExternalReference &&
        notifiedExternalReference !== order.external_reference
      ) {
        throw new Error(
          "La external_reference notificada no coincide con la order.",
        );
      }

      const notifiedStatus = firstValue(notificationData?.status);
      const notifiedStatusDetail = firstValue(
        notificationData?.status_detail,
      );
      if (
        (notifiedStatus !== undefined && notifiedStatus !== order.status) ||
        (notifiedStatusDetail !== undefined &&
          notifiedStatusDetail !== order.status_detail)
      ) {
        logger.info("La notificación tiene un estado desactualizado.");
      }

      const handler = obtenerHandler(order);
      if (handler) {
        await handler(order);
      }
      res.status(200).send();
    } catch (error) {
      logger.error(
        "No se pudo procesar la notificación de Mercado Pago.",
        error,
      );
      res.status(500).send();
    }
  },
);

/**
 * Selecciona el protocolo que corresponde al estado vigente de la order.
 * @param {MercadoPagoOrder} order Order vigente de Mercado Pago.
 * @return {OrderHandler | undefined} Handler correspondiente, si aplica.
 */
function obtenerHandler(
  order: MercadoPagoOrder,
): OrderHandler | undefined {
  switch (order.status) {
  case "processed":
    if (order.status_detail === "accredited") {
      return handlerOrderAprobada;
    }
    if (order.status_detail === "partially_refunded") {
      return handlerOrderReembolsada;
    }
    break;
  case "processing":
    if (
      order.status_detail === "in_process" ||
      order.status_detail === "pending_review_manual"
    ) {
      return handlerOrderPendiente;
    }
    break;
  case "action_required":
    if (order.status_detail === "waiting_capture") {
      return handlerOrderPendiente;
    }
    break;
  case "refunded":
    if (order.status_detail === "refunded") {
      return handlerOrderReembolsada;
    }
    break;
  case "failed":
    if (typeof order.status_detail === "string") {
      return handlerOrderRechazada;
    }
    break;
  case "canceled":
    if (order.status_detail === "canceled") {
      return handlerOrderCancelada;
    }
    break;
  }
  return undefined;
}

/**
 * Verifica la firma HMAC enviada en los headers de Mercado Pago.
 * @param {Request} req Solicitud HTTP recibida.
 * @param {string} orderId Identificador de la order notificada.
 * @return {boolean} Indica si la firma es válida.
 */
function validarFirma(req: Request, orderId: string): boolean {
  const signature = req.get("x-signature");
  const requestId = req.get("x-request-id");
  if (!signature || !requestId) return false;

  const signatureFields = Object.fromEntries(
    signature.split(",").map((part) => {
      const [key, ...valueParts] = part.trim().split("=");
      return [key, valueParts.join("=")];
    }),
  );
  const timestamp = signatureFields.ts;
  const receivedHash = signatureFields.v1;
  if (
    !timestamp ||
    !receivedHash ||
    !/^[a-f\d]{64}$/i.test(receivedHash)
  ) {
    return false;
  }

  const manifest =
    `id:${orderId.toLowerCase()};request-id:${requestId};ts:${timestamp};`;
  const expectedHash = createHmac("sha256", MP_WEBHOOK_SECRET_V2.value())
    .update(manifest)
    .digest();
  const actualHash = Buffer.from(receivedHash, "hex");
  return (
    actualHash.length === expectedHash.length &&
    timingSafeEqual(actualHash, expectedHash)
  );
}
