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
} from "../../core/utils/constants.js";
import {
  firstValue,
  isMembershipType,
  mercadoPagoApi,
  membershipActivation,
  timestampFromIso,
  type MercadoPagoAuthorizedPayment,
  type MercadoPagoPreapproval,
} from "../../shared/utils/shared.js";
import {
  cancelPreapproval,
} from "../cancel_membership_subscription/cancel_membership_subscription.js";

/**
 * Verifica la firma HMAC de una notificación de Mercado Pago.
 *
 * @param {string} signature Firma recibida en x-signature.
 * @param {string} requestId Identificador recibido en x-request-id.
 * @param {string} dataId Identificador del recurso de Mercado Pago.
 * @param {string} secret Clave secreta configurada para el webhook.
 * @return {boolean} Indica si la firma es válida.
 */
function validWebhookSignature(
  signature: string,
  requestId: string,
  dataId: string,
  secret: string,
): boolean {
  const parts: Record<string, string> = {};

  for (const part of signature.split(",")) {
    const separator = part.indexOf("=");
    if (separator < 0) continue;
    parts[part.slice(0, separator).trim()] = part.slice(separator + 1).trim();
  }

  const ts = parts["ts"];
  const received = parts["v1"];

  if (!ts || !received || !requestId || !dataId) return false;

  // Formato de firma documentado por Mercado Pago.
  const manifest =
    `id:${dataId.toLowerCase()};request-id:${requestId};ts:${ts};`;

  const expected = createHmac("sha256", secret).update(manifest).digest("hex");

  const expectedBuffer = Buffer.from(expected, "hex");
  const receivedBuffer = Buffer.from(received, "hex");

  if (expectedBuffer.length !== receivedBuffer.length) return false;

  return timingSafeEqual(expectedBuffer, receivedBuffer);
}

interface MercadoPagoPayment {
  id: number;
  status: string;
  external_reference?: string;
  transaction_amount: number;
  currency_id: string;
  point_of_interaction?: {
    type?: string;
    // En los cobros de una suscripción: subscription_id es el preapproval
    // e invoice_id el authorized_payment.
    transaction_data?: {
      subscription_id?: string;
      invoice_id?: string | number;
    };
  };
}

type WebhookOutcome =
  | "unknown_payment"
  | "mismatch"
  | "invalid_membership"
  | "user_missing"
  | "recorded"
  | "reversal_recorded"
  | "already_processed"
  | "activated"
  | "subscription_charge";

/**
 * Campos para marcar un pago ya aplicado como reembolsado o con
 * contracargo. La membresía no se retira sola: queda para revisión.
 *
 * @param {string} status Estado de Mercado Pago (refunded, ...).
 * @param {string} mpPaymentId Identificador del pago en Mercado Pago.
 * @return {Record<string, unknown>} Campos para payments/{id}.
 */
function reversalUpdate(
  status: string,
  mpPaymentId: string,
): Record<string, unknown> {
  return {
    status,
    needsReview: true,
    reviewReason: status,
    mercadoPagoPaymentId: mpPaymentId,
    reversedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

/**
 * Si el pago es un cobro automático ya registrado, aplica ahí sus
 * reembolsos o contracargos. Los cobros automáticos no usan el
 * external_reference de payments, así que se buscan por el id de MP.
 *
 * @param {MercadoPagoPayment} payment Pago consultado en Mercado Pago.
 * @return {Promise<WebhookOutcome | null>} null si no es un cobro
 *   automático conocido.
 */
async function handleSubscriptionChargePayment(
  payment: MercadoPagoPayment,
): Promise<WebhookOutcome | null> {
  const mpPaymentId = String(payment.id);
  const matches = await db
    .collection("payments")
    .where("mercadoPagoPaymentId", "==", mpPaymentId)
    .limit(5)
    .get();
  const charge = matches.docs.find(
    (doc) => doc.data().source === "subscription",
  );

  if (!charge) return null;

  // La activación de los cobros aprobados la hace
  // subscription_authorized_payment; aquí solo llegan las reversiones.
  if (!REVERSAL_STATUSES.includes(payment.status)) {
    return "subscription_charge";
  }

  const outcome = await db.runTransaction(
    async (tx): Promise<WebhookOutcome> => {
      const snapshot = await tx.get(charge.ref);
      const stored = snapshot.data() ?? {};

      if (stored.status === payment.status) return "already_processed";
      if (stored.processed !== true) {
        tx.update(charge.ref, {
          status: payment.status,
          updatedAt: FieldValue.serverTimestamp(),
        });
        return "recorded";
      }

      tx.update(charge.ref, reversalUpdate(payment.status, mpPaymentId));
      return "reversal_recorded";
    },
  );

  if (outcome === "reversal_recorded") {
    logger.warn("Reversión de un cobro automático", {
      paymentId: charge.id,
      mpPaymentId,
      status: payment.status,
    });
    await stopSubscriptionAfterChargeback(
      payment.status,
      charge.data().subscriptionId,
    );
  }

  return outcome;
}

/**
 * Un contracargo significa que el titular desconoce el cargo: se cancela
 * el cobro automático para no volver a cobrarle. (Un reembolso lo hace el
 * propio gimnasio, así que no cancela nada.)
 *
 * @param {string} status Estado de Mercado Pago del pago revertido.
 * @param {unknown} subscriptionId Documento en subscriptions.
 */
async function stopSubscriptionAfterChargeback(
  status: string,
  subscriptionId: unknown,
): Promise<void> {
  if (status !== "charged_back" || typeof subscriptionId !== "string") return;

  const subscriptionRef = db.collection("subscriptions").doc(subscriptionId);
  const stored = (await subscriptionRef.get()).data();

  if (
    !stored ||
    typeof stored.preapprovalId !== "string" ||
    !LIVE_SUBSCRIPTION_STATUSES.includes(stored.status)
  ) {
    return;
  }

  await cancelPreapproval(subscriptionId, stored.preapprovalId, status);

  const userRef = db.collection("users").doc(String(stored.uid));
  await db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    if (user.data()?.subscription_id !== subscriptionId) return;
    tx.update(userRef, {
      subscription_status: "cancelled",
      subscription_next_payment_at: FieldValue.delete(),
    });
  });
}

const NEEDS_REVIEW: readonly WebhookOutcome[] = [
  "mismatch",
  "invalid_membership",
  "user_missing",
];

/**
 * Busca el documento de subscriptions de una suscripción de Mercado Pago.
 *
 * @param {string} preapprovalId Identificador de Mercado Pago.
 * @return {Promise<object | null>} Suscripción de MP y su documento.
 */
async function loadPreapproval(preapprovalId: string): Promise<{
  preapproval: MercadoPagoPreapproval;
  subscriptionRef: FirebaseFirestore.DocumentReference;
} | null> {
  const result = await mercadoPagoApi<MercadoPagoPreapproval>(
    `/preapproval/${encodeURIComponent(preapprovalId)}`,
  );

  if (result.status === 404) return null;
  if (!result.ok) {
    throw new Error(`Mercado Pago respondió ${result.status} (preapproval)`);
  }

  const reference = result.data.external_reference;
  if (!reference) return null;

  return {
    preapproval: result.data,
    subscriptionRef: db.collection("subscriptions").doc(reference),
  };
}

/**
 * Sincroniza el estado de una suscripción (autorizada, pausada,
 * cancelada) con subscriptions/{id} y users/{uid}.
 *
 * @param {string} preapprovalId Identificador de Mercado Pago.
 * @return {Promise<string>} Resultado para el log del webhook.
 */
export async function handlePreapprovalNotification(
  preapprovalId: string,
): Promise<string> {
  const loaded = await loadPreapproval(preapprovalId);
  if (!loaded) return "unknown_subscription";

  const {preapproval, subscriptionRef} = loaded;
  const status = preapproval.status ?? "unknown";
  const nextPaymentAt = timestampFromIso(preapproval.next_payment_date);

  const outcome = await db.runTransaction(async (tx) => {
    const subscriptionSnapshot = await tx.get(subscriptionRef);
    if (!subscriptionSnapshot.exists) return "unknown_subscription";

    const stored = subscriptionSnapshot.data() ?? {};
    if (stored.preapprovalId !== preapproval.id) return "mismatch";

    const userRef = db.collection("users").doc(String(stored.uid));
    const userSnapshot = await tx.get(userRef);
    if (!userSnapshot.exists) return "user_missing";

    const userData = userSnapshot.data() ?? {};
    let isCurrent = userData.subscription_id === subscriptionRef.id;

    // Si el alumno autoriza un enlace viejo mientras ya tiene otro cobro
    // automático activo, se cancela el nuevo para no cobrarle doble.
    if (!isCurrent && LIVE_SUBSCRIPTION_STATUSES.includes(status)) {
      if (LIVE_SUBSCRIPTION_STATUSES.includes(userData.subscription_status)) {
        return "duplicate";
      }
      isCurrent = true;
    }

    tx.update(subscriptionRef, {
      status,
      nextPaymentAt: nextPaymentAt ?? FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    if (isCurrent) {
      tx.update(userRef, {
        subscription_id: subscriptionRef.id,
        subscription_status: status,
        subscription_membership_type: stored.membershipType,
        subscription_next_payment_at:
          status === "authorized" && nextPaymentAt ?
            nextPaymentAt :
            FieldValue.delete(),
      });
    }

    return "synced";
  });

  if (outcome === "duplicate") {
    await cancelPreapproval(subscriptionRef.id, preapprovalId, "duplicate");
  }

  return outcome;
}

/**
 * Procesa un cobro de una suscripción: si se aprobó, extiende la
 * membresía (una sola vez por cobro).
 *
 * @param {string} authorizedPaymentId Identificador del cobro en MP.
 * @return {Promise<string>} Resultado para el log del webhook.
 */
async function handleAuthorizedPaymentNotification(
  authorizedPaymentId: string,
): Promise<string> {
  const result = await mercadoPagoApi<MercadoPagoAuthorizedPayment>(
    `/authorized_payments/${encodeURIComponent(authorizedPaymentId)}`,
  );

  if (result.status === 404) return "unknown_payment";
  if (!result.ok) {
    throw new Error(
      `Mercado Pago respondió ${result.status} (authorized_payments)`,
    );
  }

  const charge = result.data;
  if (!charge.preapproval_id) return "unknown_subscription";

  const loaded = await loadPreapproval(charge.preapproval_id);
  if (!loaded) return "unknown_subscription";

  const {subscriptionRef} = loaded;
  const paymentRef = db
    .collection("payments")
    .doc(`mp_subscription_${authorizedPaymentId}`);
  const paymentStatus = charge.payment?.status ?? charge.status ?? "pending";

  const outcome = await db.runTransaction(async (tx) => {
    const subscriptionSnapshot = await tx.get(subscriptionRef);
    if (!subscriptionSnapshot.exists) return "unknown_subscription";

    const stored = subscriptionSnapshot.data() ?? {};

    if (
      stored.preapprovalId !== charge.preapproval_id ||
      charge.currency_id !== stored.currency ||
      Math.abs(Number(charge.transaction_amount) - Number(stored.amount)) >
        0.009
    ) {
      logger.error("Cobro de suscripción que no coincide", {
        authorizedPaymentId,
        subscriptionId: subscriptionRef.id,
      });
      return "mismatch";
    }

    if (!isMembershipType(stored.membershipType)) {
      return "invalid_membership";
    }

    const paymentSnapshot = await tx.get(paymentRef);
    const storedCharge = paymentSnapshot.data();
    if (storedCharge?.processed === true) {
      // Ya extendió la membresía: solo se registran reembolsos o
      // contracargos (también llegan por el webhook de "payment").
      if (
        REVERSAL_STATUSES.includes(paymentStatus) &&
        storedCharge.status !== paymentStatus
      ) {
        tx.update(
          paymentRef,
          reversalUpdate(
            paymentStatus,
            String(charge.payment?.id ?? storedCharge.mercadoPagoPaymentId),
          ),
        );
        return "reversal_recorded";
      }
      return "already_processed";
    }

    const userRef = db.collection("users").doc(String(stored.uid));
    const userSnapshot = await tx.get(userRef);
    if (!userSnapshot.exists) return "user_missing";

    const membership = MEMBERSHIPS[stored.membershipType];
    const approved = paymentStatus === "approved";

    // Mismo formato que los pagos del checkout, para que el historial
    // y la pantalla de inicio los traten igual.
    tx.set(
      paymentRef,
      {
        uid: stored.uid,
        membershipType: stored.membershipType,
        membershipPlanId: membership.planId,
        membershipAmount: membership.amount,
        registrationFee: 0,
        amount: stored.amount,
        currency: stored.currency,
        status: paymentStatus,
        provider: "mercadopago",
        source: "subscription",
        subscriptionId: subscriptionRef.id,
        mercadoPagoAuthorizedPaymentId: authorizedPaymentId,
        mercadoPagoPaymentId:
          charge.payment?.id === undefined ? null : String(charge.payment.id),
        processed: approved,
        updatedAt: FieldValue.serverTimestamp(),
        ...(paymentSnapshot.exists ?
          {} :
          {createdAt: FieldValue.serverTimestamp()}),
        ...(approved ? {approvedAt: FieldValue.serverTimestamp()} : {}),
      },
      {merge: true},
    );

    if (!approved) return "recorded";

    tx.update(userRef, {
      ...membershipActivation(
        stored.membershipType,
        userSnapshot.data()?.membership_expires_at,
      ),
      last_payment_id: paymentRef.id,
    });

    return "activated";
  });

  if (outcome === "reversal_recorded") {
    logger.warn("Reversión de un cobro automático", {
      paymentId: paymentRef.id,
      status: paymentStatus,
    });
    await stopSubscriptionAfterChargeback(paymentStatus, subscriptionRef.id);
  }

  return outcome;
}

const SUBSCRIPTION_HANDLERS: Record<
  string,
  (dataId: string) => Promise<string>
> = {
  subscription_preapproval: handlePreapprovalNotification,
  subscription_authorized_payment: handleAuthorizedPaymentNotification,
};

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
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    // Mercado Pago también envía merchant_order, etc. Solo nos interesan
    // los pagos y las suscripciones; el resto se confirma con 200 para que
    // no reintente. (Ignorarlos no ejecuta nada, así que no hace falta
    // validar la firma.)
    const notificationType =
      firstValue(req.query["type"]) ??
      firstValue(req.query["topic"]) ??
      firstValue(req.body?.type) ??
      firstValue(req.body?.topic) ??
      "";
    const subscriptionHandler = Object.prototype.hasOwnProperty.call(
      SUBSCRIPTION_HANDLERS,
      notificationType,
    ) ?
      SUBSCRIPTION_HANDLERS[notificationType] :
      undefined;

    if (notificationType !== "payment" && !subscriptionHandler) {
      res.status(200).send("Ignored notification type");
      return;
    }

    const dataId =
      firstValue(req.query["data.id"]) ?? firstValue(req.body?.data?.id) ?? "";
    const requestId = String(req.header("x-request-id") ?? "");
    const signature = String(req.header("x-signature") ?? "");

    if (
      !validWebhookSignature(
        signature,
        requestId,
        dataId,
        MP_WEBHOOK_SECRET.value(),
      )
    ) {
      // Si esto aparece con pagos reales, MP_WEBHOOK_SECRET no coincide
      // con la clave secreta de "Tus integraciones > Webhooks".
      logger.warn("Firma de webhook inválida", {
        dataId,
        hasSignature: signature !== "",
        hasRequestId: requestId !== "",
      });
      res.status(401).send("Invalid signature");
      return;
    }

    if (subscriptionHandler) {
      try {
        const outcome = await subscriptionHandler(dataId);
        logger.info("Notificación de suscripción procesada", {
          notificationType,
          dataId,
          outcome,
        });
        res.status(200).send(outcome);
      } catch (error) {
        // 5xx para que Mercado Pago reintente más tarde.
        logger.error("Error procesando notificación de suscripción", error);
        res.status(500).send("Subscription processing failed");
      }
      return;
    }

    try {
      // No confiamos en el estado enviado por el navegador o el webhook:
      // consultamos el recurso directamente con Mercado Pago.
      const mpResponse = await fetch(
        `https://api.mercadopago.com/v1/payments/${encodeURIComponent(dataId)}`,
        {
          headers: {Authorization: `Bearer ${MP_ACCESS_TOKEN.value()}`},
          signal: AbortSignal.timeout(MP_TIMEOUT_MS),
        },
      );

      if (mpResponse.status === 404) {
        // Pago inexistente (p. ej. notificaciones de prueba del panel).
        res.status(200).send("Payment not found");
        return;
      }

      if (!mpResponse.ok) {
        const errorBody = await mpResponse.text();
        logger.error("Mercado Pago rechazó la consulta del pago", {
          httpStatus: mpResponse.status,
          paymentId: dataId,
          response: errorBody.slice(0, 1000),
        });
        // 5xx para que Mercado Pago reintente más tarde.
        res.status(502).send("Could not verify payment");
        return;
      }

      const payment = (await mpResponse.json()) as MercadoPagoPayment;

      const subscriptionOutcome =
        await handleSubscriptionChargePayment(payment);
      if (subscriptionOutcome) {
        res.status(200).send(subscriptionOutcome);
        return;
      }

      // Cobro de una suscripción que aún no conocemos (p. ej. si el aviso
      // subscription_authorized_payment no llegó): se procesa igual.
      const invoiceId =
        payment.point_of_interaction?.transaction_data?.invoice_id;
      if (
        payment.point_of_interaction?.type === "SUBSCRIPTIONS" &&
        invoiceId !== undefined &&
        invoiceId !== null
      ) {
        const outcome = await handleAuthorizedPaymentNotification(
          String(invoiceId),
        );
        logger.info("Cobro de suscripción recibido como payment", {
          mpPaymentId: String(payment.id),
          invoiceId: String(invoiceId),
          outcome,
        });
        res.status(200).send(outcome);
        return;
      }

      const internalPaymentId = payment.external_reference;

      if (!internalPaymentId) {
        res.status(200).send("No internal reference");
        return;
      }

      const paymentRef = db.collection("payments").doc(internalPaymentId);
      const mpPaymentId = String(payment.id);

      // Todo ocurre en una transacción: así una notificación atrasada
      // ("pending") nunca puede pisar a una ya aprobada, y dos
      // notificaciones simultáneas no activan la membresía dos veces.
      const outcome = await db.runTransaction(
        async (tx): Promise<WebhookOutcome> => {
          const paymentSnapshot = await tx.get(paymentRef);

          if (!paymentSnapshot.exists) return "unknown_payment";

          const stored = paymentSnapshot.data() ?? {};

          // Confirma que el pago pertenece a la operación que creamos.
          if (
            stored.provider !== "mercadopago" ||
            payment.currency_id !== stored.currency ||
            Math.abs(
              Number(payment.transaction_amount) - Number(stored.amount),
            ) > 0.009
          ) {
            return "mismatch";
          }

          if (stored.processed === true) {
            // Ya activada: solo se registran reembolsos o contracargos.
            if (REVERSAL_STATUSES.includes(payment.status)) {
              tx.update(
                paymentRef,
                reversalUpdate(payment.status, mpPaymentId),
              );
              return "reversal_recorded";
            }
            return "already_processed";
          }

          // Solo se activa una membresía cuando el estado es approved.
          if (payment.status !== "approved") {
            tx.update(paymentRef, {
              status: payment.status,
              mercadoPagoPaymentId: mpPaymentId,
              updatedAt: FieldValue.serverTimestamp(),
            });
            return "recorded";
          }

          if (!isMembershipType(stored.membershipType)) {
            return "invalid_membership";
          }

          const userRef = db.collection("users").doc(String(stored.uid));
          const userSnapshot = await tx.get(userRef);

          if (!userSnapshot.exists) return "user_missing";

          const userUpdate: Record<string, unknown> = {
            ...membershipActivation(
              stored.membershipType,
              userSnapshot.data()?.membership_expires_at,
            ),
            last_payment_id: paymentRef.id,
          };

          if (Number(stored.registrationFee ?? 0) > 0) {
            userUpdate.registration_payed = true;
          }

          tx.update(userRef, userUpdate);
          tx.update(paymentRef, {
            status: "approved",
            processed: true,
            mercadoPagoPaymentId: mpPaymentId,
            approvedAt: FieldValue.serverTimestamp(),
          });

          return "activated";
        },
      );

      if (NEEDS_REVIEW.includes(outcome)) {
        // Se responde 200 (reintentar no lo arreglaría) pero se deja
        // marcado para revisión manual.
        logger.error("Pago aprobado que requiere revisión", {
          outcome,
          internalPaymentId,
          mpPaymentId,
        });
        await paymentRef.update({
          needsReview: true,
          reviewReason: outcome,
          mercadoPagoPaymentId: mpPaymentId,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      res.status(200).send(outcome);
    } catch (error) {
      logger.error("Error procesando webhook", error);
      res.status(500).send("Webhook processing failed");
    }
  },
);
