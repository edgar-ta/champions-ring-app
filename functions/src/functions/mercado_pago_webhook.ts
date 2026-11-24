import {createHmac, timingSafeEqual} from "node:crypto";
import type {
  DocumentData,
  DocumentReference,
} from "firebase-admin/firestore";
import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {MercadoPagoConfig, Order} from "mercadopago";
import type {Request} from "express";
import {onRequest} from "firebase-functions/v2/https";
import {
  db,
  MP_ACCESS_TOKEN_V2,
  MP_TIMEOUT_MS,
  MP_WEBHOOK_SECRET_V2,
  REGION,
} from "../core/utils/constants.js";
import {firstValue} from "../shared/utils/shared.js";

interface MercadoPagoOrder {
  id: string;
  external_reference?: string;
  status?: string;
  status_detail?: string;
}

interface MercadoPagoNotification {
  type?: unknown;
  data?: unknown;
  external_reference?: unknown;
  status?: unknown;
  status_detail?: unknown;
}

interface PaymentRecord {
  paymentRef: DocumentReference;
  paymentData: DocumentData;
}

type OrderHandler = (order: MercadoPagoOrder) => Promise<void>;

/**
 * Recupera una order de Mercado Pago mediante GET /v1/orders/{id}.
 * @param {string} orderId Identificador de la order.
 * @return {Promise<MercadoPagoOrder>} Order recuperada.
 */
export async function recuperarOrder(
  orderId: string,
): Promise<MercadoPagoOrder> {
  if (orderId.trim() === "" || orderId.includes("/")) {
    throw new TypeError("El identificador de la order no es válido.");
  }

  const client = new MercadoPagoConfig({
    accessToken: MP_ACCESS_TOKEN_V2.value(),
    options: {timeout: MP_TIMEOUT_MS},
  });
  const response = await new Order(client).get({id: orderId});

  if (response.id !== orderId) {
    throw new Error("Mercado Pago no devolvió la order solicitada.");
  }

  return {
    id: response.id,
    external_reference: response.external_reference,
    status: response.status,
    status_detail: response.status_detail,
  };
}

/**
 * Aplica el protocolo 1 y, si corresponde, enlaza la renovación al miembro.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderAprobada(
  order: MercadoPagoOrder,
): Promise<void> {
  const {paymentRef, paymentData} = await recuperarPago(order);
  const update = {
    status: "approved",
    approvalDate: FieldValue.serverTimestamp(),
  };
  const renewalRefValue = paymentData.renewalRef;

  if (renewalRefValue === undefined || renewalRefValue === null) {
    await paymentRef.update(update);
    return;
  }
  const renewalRef = asDocumentReference(renewalRefValue);
  if (!renewalRef) {
    throw new TypeError("El atributo renewalRef del pago no es válido.");
  }

  const payerRef = asDocumentReference(paymentData.payerRef);
  if (!payerRef) {
    throw new Error(
      "El pago asociado a una renovación debe incluir payerRef.",
    );
  }
  const memberId = payerRef.path.split("/").pop();
  if (!memberId) {
    throw new Error("No se pudo determinar el miembro asociado al pago.");
  }

  const memberRef = db.collection("members").doc(memberId);
  const memberSnapshot = await memberRef.get();
  if (!memberSnapshot.exists) {
    throw new Error(`No existe el miembro "${memberId}" asociado al pago.`);
  }

  const batch = db.batch();
  batch.update(paymentRef, update);
  batch.update(memberRef, {latestRenewalRef: renewalRef});
  await batch.commit();
}

/**
 * Aplica el protocolo 2 y marca el pago como processing.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderPendiente(
  order: MercadoPagoOrder,
): Promise<void> {
  const {paymentRef} = await recuperarPago(order);
  await paymentRef.update({status: "processing"});
}

/**
 * Aplica el protocolo 3 y marca el pago como refunded.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderReembolsada(
  order: MercadoPagoOrder,
): Promise<void> {
  const {paymentRef} = await recuperarPago(order);
  await paymentRef.update({status: "refunded"});
}

/**
 * Aplica el protocolo 4 y guarda el detalle de rechazo de la order.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderRechazada(
  order: MercadoPagoOrder,
): Promise<void> {
  if (typeof order.status_detail !== "string") {
    throw new TypeError("La order rechazada no incluye status_detail.");
  }
  const {paymentRef} = await recuperarPago(order);
  await paymentRef.update({
    status: "rejected",
    rejectionDetail: order.status_detail,
  });
}

/**
 * Aplica el protocolo 5 y marca el pago como canceled.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderCancelada(
  order: MercadoPagoOrder,
): Promise<void> {
  const {paymentRef} = await recuperarPago(order);
  await paymentRef.update({status: "canceled"});
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
    if (notificationType !== "orders") {
      res.status(200).send();
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
 * Recupera el documento de pago asociado a la order.
 * @param {MercadoPagoOrder} order Order vigente de Mercado Pago.
 * @return {Promise<PaymentRecord>} Referencia y datos del pago.
 */
async function recuperarPago(
  order: MercadoPagoOrder,
): Promise<PaymentRecord> {
  const paymentId = order.external_reference;
  if (
    typeof paymentId !== "string" ||
    paymentId.trim() === "" ||
    paymentId.includes("/")
  ) {
    throw new TypeError("La order no incluye una referencia externa válida.");
  }

  const paymentRef = db.collection("payments").doc(paymentId);
  const paymentSnapshot = await paymentRef.get();
  if (!paymentSnapshot.exists) {
    throw new Error(`No existe el pago "${paymentId}" asociado a la order.`);
  }
  return {paymentRef, paymentData: paymentSnapshot.data() ?? {}};
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
 * Comprueba que un valor sea un objeto con propiedades indexables.
 * @param {unknown} value Valor que se comprobará.
 * @return {Record<string, unknown> | null} Objeto o null.
 */
function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value) ?
    value as Record<string, unknown> :
    null;
}

/**
 * Convierte un valor a referencia Firestore después de validar su forma.
 * @param {unknown} value Valor que se comprobará.
 * @return {DocumentReference | undefined} Referencia válida, si existe.
 */
function asDocumentReference(
  value: unknown,
): DocumentReference | undefined {
  if (
    typeof value === "object" &&
    value !== null &&
    "path" in value &&
    typeof value.path === "string" &&
    "get" in value &&
    typeof value.get === "function"
  ) {
    return value as DocumentReference;
  }
  return undefined;
}
