/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions, logger} from "firebase-functions";
// import {onRequest} from "firebase-functions/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


import {initializeApp} from "firebase-admin/app";
import {
  getFirestore,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {createHmac, timingSafeEqual} from "node:crypto";

initializeApp();

const db = getFirestore();

const MP_ACCESS_TOKEN = defineSecret("MP_ACCESS_TOKEN");
const MP_WEBHOOK_SECRET = defineSecret("MP_WEBHOOK_SECRET");

// IMPORTANTE: reemplaza estos importes con los precios reales
const MEMBERSHIPS = {
  day: {
    amount: 69,
    days: 1,
    label: "Acceso por 1 día",
    planId: 1,
  },
  week: {
    amount: 180,
    days: 7,
    label: "Acceso por 1 semana",
    planId: 2,
  },
  month: {
    amount: 600,
    days: 30,
    label: "Acceso por 1 mes",
    planId: 3,
  },
} as const;

type MembershipType = keyof typeof MEMBERSHIPS;

// 1. Flutter llama a esta función para iniciar un pago.
export const createMembershipCheckout = onCall(
  {
    region: "us-central1",
    secrets: [MP_ACCESS_TOKEN],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para pagar."
      );
    }

    const uid = request.auth.uid;
    const type = request.data?.membershipType as MembershipType;

    if (!Object.prototype.hasOwnProperty.call(MEMBERSHIPS, type)) {
      throw new HttpsError(
        "invalid-argument",
        "El tipo de membresía no es válido."
      );
    }

    const membership = MEMBERSHIPS[type];

    if (!Number.isFinite(membership.amount) || membership.amount <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Configura el precio de esta membresía."
      );
    }

    // Cambia "users" si tus perfiles viven en otra colección.
    const userRef = db.collection("users").doc(uid);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No existe el perfil del alumno."
      );
    }

    const userData = userSnapshot.data()!;

    // El campo corresponde al que guarda CoreUser.toFirebaseMap().
    const registrationAlreadyPaid =
      userData.registration_payed === true;

    // La inscripción solo aplica a semana y mes,
    // y únicamente si aún no se ha pagado.
    const registrationFee =
      (type === "week" || type === "month") &&
      !registrationAlreadyPaid ?
        120 :
        0;

    const totalAmount = membership.amount + registrationFee;


    // Se crea una referencia propia antes de contactar con Mercado Pago.
    const paymentRef = db.collection("payments").doc();

    await paymentRef.set({
      uid,
      membershipType: type,
      membershipPlanId: membership.planId,
      membershipAmount: membership.amount,
      registrationFee,
      amount: totalAmount,
      currency: "MXN",
      status: "pending",
      provider: "mercadopago",
      processed: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    const response = await fetch(
      "https://api.mercadopago.com/checkout/preferences",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${MP_ACCESS_TOKEN.value()}`,
          "Content-Type": "application/json",
          "X-Idempotency-Key": paymentRef.id,
        },
        body: JSON.stringify({
          items: [
            {
              id: type,
              title: membership.label,
              quantity: 1,
              currency_id: "MXN",
              unit_price: membership.amount,
            },
            ...(registrationFee > 0 ?
              [
                {
                  id: "registration",
                  title: "Inscripción Champions Ring",
                  quantity: 1,
                  currency_id: "MXN",
                  unit_price: registrationFee,
                },
              ] :
              []),
          ],
          external_reference: paymentRef.id,
          metadata: {
            firebase_uid: uid,
            membership_type: type,
          },
          notification_url: "https://mercadopagowebhook-4zaqwydcxq-uc.a.run.app",
          auto_return: "approved",
        }),
      }
    );

    const result = await response.json() as {
      id?: string;
      init_point?: string;
      sandbox_init_point?: string;
      message?: string;
    };

    if (!response.ok || !result.id || !result.init_point) {
      logger.error("Error al crear preferencia", {
        status: response.status,
        response: result,
      });

      await paymentRef.update({
        status: "checkout_creation_failed",
      });

      throw new HttpsError(
        "internal",
        "No fue posible iniciar el pago."
      );
    }

    await paymentRef.update({
      preferenceId: result.id,
    });

    return {
      paymentId: paymentRef.id,
      checkoutUrl: result.init_point,
      sandboxCheckoutUrl: result.sandbox_init_point ?? null,
    };
  }
);

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
  secret: string
): boolean {
  const parts = Object.fromEntries(
    signature.split(",").map((part) => {
      const separator = part.indexOf("=");
      return [
        part.slice(0, separator).trim(),
        part.slice(separator + 1).trim(),
      ];
    })
  );

  const ts = parts["ts"];
  const received = parts["v1"];

  if (!ts || !received || !requestId || !dataId) return false;

  // Formato de firma documentado por Mercado Pago.
  const manifest =
    `id:${dataId.toLowerCase()};request-id:${requestId};ts:${ts};`;

  const expected = createHmac("sha256", secret)
    .update(manifest)
    .digest("hex");

  const expectedBuffer = Buffer.from(expected, "hex");
  const receivedBuffer = Buffer.from(received, "hex");

  if (expectedBuffer.length !== receivedBuffer.length) return false;

  return timingSafeEqual(expectedBuffer, receivedBuffer);
}

/**
 * Recibe y valida las notificaciones de pago de Mercado Pago.
 */
export const mercadoPagoWebhook = onRequest(
  {
    region: "us-central1",
    secrets: [MP_ACCESS_TOKEN, MP_WEBHOOK_SECRET],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const rawDataId = req.query["data.id"];
    const queryId = Array.isArray(rawDataId) ? rawDataId[0] : rawDataId;
    const bodyId = req.body?.data?.id;

    const dataId = String(queryId ?? bodyId ?? "");
    const requestId = String(req.header("x-request-id") ?? "");
    const signature = String(req.header("x-signature") ?? "");

    if (
      !validWebhookSignature(
        signature,
        requestId,
        dataId,
        MP_WEBHOOK_SECRET.value()
      )
    ) {
      res.status(401).send("Invalid signature");
      return;
    }

    try {
      // No confiamos en el estado enviado por el navegador o el webhook:
      // consultamos el recurso directamente con Mercado Pago.
      const mpResponse = await fetch(
        `https://api.mercadopago.com/v1/payments/${encodeURIComponent(dataId)}`,
        {
          headers: {
            Authorization: `Bearer ${MP_ACCESS_TOKEN.value()}`,
          },
        }
      );

      if (!mpResponse.ok) {
        const errorBody = await mpResponse.text();
        logger.error("Mercado Pago rechazó la consulta del pago", {
          httpStatus: mpResponse.status,
          paymentId: dataId,
          response: errorBody.slice(0, 1000),
        });
        res.status(502).send("Could not verify payment");
        return;
      }

      const payment = await mpResponse.json() as {
        id: number;
        status: string;
        external_reference?: string;
        transaction_amount: number;
        currency_id: string;
      };

      const internalPaymentId = payment.external_reference;

      if (!internalPaymentId) {
        res.status(200).send("No internal reference");
        return;
      }

      const paymentRef = db.collection("payments").doc(internalPaymentId);
      const paymentSnapshot = await paymentRef.get();

      if (!paymentSnapshot.exists) {
        res.status(200).send("Unknown payment");
        return;
      }

      const storedPayment = paymentSnapshot.data()!;

      // Confirma que el pago pertenece a la operación que creamos.
      if (
        storedPayment.provider !== "mercadopago" ||
        Number(payment.transaction_amount) !== Number(storedPayment.amount) ||
        payment.currency_id !== "MXN"
      ) {
        logger.error("No coincide el importe o la moneda", {
          internalPaymentId,
          mpPaymentId: payment.id,
        });
        res.status(400).send("Payment mismatch");
        return;
      }

      // Solo se activa una membresía cuando el estado es approved.
      if (payment.status !== "approved") {
        await paymentRef.update({
          status: payment.status,
          mercadoPagoPaymentId: String(payment.id),
          updatedAt: FieldValue.serverTimestamp(),
        });

        res.status(200).send("Payment status recorded");
        return;
      }

      const membershipType =
        storedPayment.membershipType as MembershipType;

      const membership = MEMBERSHIPS[membershipType];

      if (!membership || storedPayment.processed === true) {
        res.status(200).send("Already processed or invalid membership");
        return;
      }

      // Cambia la colección y los campos si tu modelo usa otros nombres.
      const userRef = db.collection("users").doc(storedPayment.uid);

      await db.runTransaction(async (transaction) => {
        const freshPayment = await transaction.get(paymentRef);
        const freshUser = await transaction.get(userRef);

        if (!freshPayment.exists || !freshUser.exists) {
          throw new Error("Payment or user does not exist");
        }

        if (freshPayment.data()?.processed === true) {
          return;
        }

        const userData = freshUser.data()!;
        const currentExpiry = userData.membershipExpiresAt;

        const now = Date.now();
        const oldExpiry =
          currentExpiry instanceof Timestamp ?
            currentExpiry.toMillis() :
            0;

        // Si la membresía sigue vigente, se extiende desde su vencimiento.
        // Si ya venció, comienza desde el momento del pago.
        const base = Math.max(now, oldExpiry);
        const newExpiry = Timestamp.fromMillis(
          base + membership.days * 24 * 60 * 60 * 1000
        );

        transaction.update(userRef, {
          membership_plan_id: membership.planId,
          tipoMembresia: membershipType,
          estadoMembresia: "activa",
          membershipExpiresAt: newExpiry,
          ...(Number(freshPayment.data()?.registrationFee ?? 0) > 0 ?
            {registration_payed: true} :
            {}),
          updatedAt: FieldValue.serverTimestamp(),
        });

        transaction.update(paymentRef, {
          status: "approved",
          processed: true,
          mercadoPagoPaymentId: String(payment.id),
          approvedAt: FieldValue.serverTimestamp(),
        });
      });

      res.status(200).send("Payment verified and processed");
    } catch (error) {
      logger.error("Error procesando webhook", error);
      res.status(500).send("Webhook processing failed");
    }
  }
);
