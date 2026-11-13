import {setGlobalOptions, logger} from "firebase-functions";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  getFirestore,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {createHmac, timingSafeEqual} from "node:crypto";

// Control de costos: máximo de contenedores simultáneos por función.
setGlobalOptions({maxInstances: 10});

initializeApp();

const REGION = "us-central1";

// ---------------------------------------------------------------------------
// Configuración (se puede sobrescribir con functions/.env, ver .env.example)
// ---------------------------------------------------------------------------

// La app de Flutter abre Firestore con databaseId: "default"
// (lib/core/firebase/firestore_instance.dart). Las funciones deben usar la
// MISMA base de datos. Si tu base se llama "(default)", define
// FIRESTORE_DATABASE_ID=(default) en functions/.env.
const DATABASE_ID = process.env.FIRESTORE_DATABASE_ID ?? "default";
const db = DATABASE_ID === "(default)" ?
  getFirestore() :
  getFirestore(DATABASE_ID);

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? "champions-ring-app";
const FUNCTIONS_BASE_URL =
  `https://${REGION}-${PROJECT_ID}.cloudfunctions.net`;

// source_news=webhooks: sin esto Mercado Pago también envía notificaciones
// IPN (?topic=payment&id=...), que no traen data.id y fallan la firma.
const NOTIFICATION_URL =
  process.env.MP_NOTIFICATION_URL ??
  `${FUNCTIONS_BASE_URL}/mercadoPagoWebhook?source_news=webhooks`;

const RETURN_URL =
  process.env.PAYMENT_RETURN_URL ??
  `${FUNCTIONS_BASE_URL}/paymentReturn`;

// Solo para pruebas: devuelve el checkout sandbox en lugar del real.
const USE_SANDBOX = process.env.MP_USE_SANDBOX === "true";

const MP_ACCESS_TOKEN = defineSecret("MP_ACCESS_TOKEN");
const MP_WEBHOOK_SECRET = defineSecret("MP_WEBHOOK_SECRET");

// ---------------------------------------------------------------------------
// Precios (fuente de verdad: el servidor)
// ---------------------------------------------------------------------------

// IMPORTANTE: mantén estos importes iguales a lib/.../membership_plan.dart.
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

const REGISTRATION_FEE = 120;
const REGISTRATION_REQUIRED_FOR: readonly MembershipType[] = ["week", "month"];

// Planes que se pueden renovar con cobro automático (la inscripción
// nunca entra: se cobra una sola vez con el checkout normal).
const RECURRING_TYPES: readonly MembershipType[] = ["week", "month"];

// Estados de una suscripción de Mercado Pago que todavía cobran.
const LIVE_SUBSCRIPTION_STATUSES: readonly string[] = ["authorized", "paused"];

// Un checkout pendiente reciente se reutiliza en lugar de crear otro.
const REUSE_WINDOW_MS = 30 * 60 * 1000;
const MP_TIMEOUT_MS = 15 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

const REVERSAL_STATUSES: readonly string[] = [
  "refunded",
  "charged_back",
  "cancelled",
];

/**
 * Indica si el valor recibido es un tipo de membresía válido.
 *
 * @param {unknown} value Valor enviado por el cliente.
 * @return {boolean} true si existe en MEMBERSHIPS.
 */
function isMembershipType(value: unknown): value is MembershipType {
  return typeof value === "string" &&
    Object.prototype.hasOwnProperty.call(MEMBERSHIPS, value);
}

/**
 * Calcula el costo de inscripción que aplica a esta compra.
 *
 * @param {MembershipType} type Tipo de membresía.
 * @param {boolean} alreadyPaid Si el usuario ya pagó su inscripción.
 * @return {number} Importe de la inscripción (0 si no aplica).
 */
function registrationFeeFor(
  type: MembershipType,
  alreadyPaid: boolean
): number {
  if (alreadyPaid) return 0;
  return REGISTRATION_REQUIRED_FOR.includes(type) ? REGISTRATION_FEE : 0;
}

/**
 * Calcula los campos del usuario que activan o extienden su membresía.
 *
 * @param {MembershipType} type Tipo de membresía pagada.
 * @param {unknown} currentExpiry Valor actual de membership_expires_at.
 * @return {Record<string, unknown>} Campos para actualizar users/{uid}.
 */
function membershipActivation(
  type: MembershipType,
  currentExpiry: unknown
): Record<string, unknown> {
  const membership = MEMBERSHIPS[type];
  const oldExpiry =
    currentExpiry instanceof Timestamp ? currentExpiry.toMillis() : 0;

  // Si la membresía sigue vigente se extiende desde su vencimiento;
  // si ya venció, comienza desde el momento del pago.
  const base = Math.max(Date.now(), oldExpiry);

  return {
    membership_plan_id: membership.planId,
    membership_type: type,
    membership_status: "active",
    membership_expires_at: Timestamp.fromMillis(
      base + membership.days * DAY_MS
    ),
    updated_at: FieldValue.serverTimestamp(),
  };
}

/**
 * Llama a la API de Mercado Pago con el access token del vendedor.
 *
 * @param {string} path Ruta de la API, p. ej. "/preapproval".
 * @param {object} options Método, cuerpo y clave de idempotencia.
 * @return {Promise<object>} Código HTTP y cuerpo JSON de la respuesta.
 */
async function mercadoPagoApi<T>(
  path: string,
  options: {
    method?: "GET" | "POST" | "PUT";
    body?: unknown;
    idempotencyKey?: string;
  } = {}
): Promise<{ok: boolean; status: number; data: T}> {
  const headers: Record<string, string> = {
    "Authorization": `Bearer ${MP_ACCESS_TOKEN.value()}`,
  };
  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  if (options.idempotencyKey) {
    headers["X-Idempotency-Key"] = options.idempotencyKey;
  }

  const response = await fetch(`https://api.mercadopago.com${path}`, {
    method: options.method ?? "GET",
    headers,
    signal: AbortSignal.timeout(MP_TIMEOUT_MS),
    body: options.body === undefined ?
      undefined :
      JSON.stringify(options.body),
  });
  const data = await response.json().catch(() => ({})) as T;

  return {ok: response.ok, status: response.status, data};
}

/**
 * Convierte una fecha ISO de Mercado Pago en Timestamp.
 *
 * @param {unknown} value Fecha en texto (o nada).
 * @return {Timestamp | null} Timestamp, o null si no es válida.
 */
function timestampFromIso(value: unknown): Timestamp | null {
  if (typeof value !== "string") return null;
  const millis = Date.parse(value);
  return Number.isNaN(millis) ? null : Timestamp.fromMillis(millis);
}

/**
 * Devuelve el primer valor de un parámetro que puede venir repetido.
 *
 * @param {unknown} value Valor de req.query o req.body.
 * @return {string | undefined} Primer valor como texto.
 */
function firstValue(value: unknown): string | undefined {
  const first = Array.isArray(value) ? value[0] : value;
  if (first === undefined || first === null || first === "") {
    return undefined;
  }
  return String(first);
}

// ---------------------------------------------------------------------------
// 0. Registro: indica si un correo ya tiene cuenta, para avisarlo en el
//    primer paso del formulario y no hasta crear la cuenta al final.
// ---------------------------------------------------------------------------

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const checkEmailAvailable = onCall(
  // Público: se llama antes de que exista la cuenta del usuario.
  {region: REGION, invoker: "public"},
  async (request) => {
    const email: unknown = request.data?.email;

    if (
      typeof email !== "string" ||
      email.length > 254 ||
      !EMAIL_PATTERN.test(email.trim())
    ) {
      throw new HttpsError("invalid-argument", "El correo no es válido.");
    }

    try {
      await getAuth().getUserByEmail(email.trim());
      return {available: false};
    } catch (error) {
      if ((error as {code?: string}).code === "auth/user-not-found") {
        return {available: true};
      }
      logger.error("No se pudo verificar el correo", error);
      throw new HttpsError("internal", "No se pudo verificar el correo.");
    }
  }
);

// ---------------------------------------------------------------------------
// 1. Flutter llama a esta función para iniciar un pago.
// ---------------------------------------------------------------------------

export const createMembershipCheckout = onCall(
  {
    region: REGION,
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
    const type: unknown = request.data?.membershipType;

    if (!isMembershipType(type)) {
      throw new HttpsError(
        "invalid-argument",
        "El tipo de membresía no es válido."
      );
    }

    const membership = MEMBERSHIPS[type];

    const userSnapshot = await db.collection("users").doc(uid).get();

    if (!userSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No existe el perfil del alumno."
      );
    }

    const userData = userSnapshot.data() ?? {};
    const registrationFee = registrationFeeFor(
      type,
      userData.registration_payed === true
    );
    const totalAmount = membership.amount + registrationFee;

    // Si hay un checkout reciente igual, se reutiliza (evita acumular
    // documentos "pending" cuando el usuario toca el botón varias veces).
    const recent = await db.collection("payments")
      .where("uid", "==", uid)
      .where("status", "==", "pending")
      .limit(10)
      .get();

    const reusable = recent.docs.find((doc) => {
      const data = doc.data();
      const createdAt =
        data.createdAt instanceof Timestamp ? data.createdAt.toMillis() : 0;
      return data.membershipType === type &&
        data.amount === totalAmount &&
        typeof data.checkoutUrl === "string" &&
        Date.now() - createdAt < REUSE_WINDOW_MS;
    });

    if (reusable) {
      return {
        paymentId: reusable.id,
        checkoutUrl: reusable.data().checkoutUrl as string,
      };
    }

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

    const items: Array<Record<string, unknown>> = [
      {
        id: type,
        title: membership.label,
        quantity: 1,
        currency_id: "MXN",
        unit_price: membership.amount,
      },
    ];

    if (registrationFee > 0) {
      items.push({
        id: "registration",
        title: "Inscripción Champions Ring",
        quantity: 1,
        currency_id: "MXN",
        unit_price: registrationFee,
      });
    }

    let response: Response;

    try {
      response = await fetch(
        "https://api.mercadopago.com/checkout/preferences",
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${MP_ACCESS_TOKEN.value()}`,
            "Content-Type": "application/json",
            "X-Idempotency-Key": paymentRef.id,
          },
          signal: AbortSignal.timeout(MP_TIMEOUT_MS),
          body: JSON.stringify({
            items,
            external_reference: paymentRef.id,
            metadata: {
              firebase_uid: uid,
              membership_type: type,
            },
            notification_url: NOTIFICATION_URL,
            // Mercado Pago EXIGE back_urls.success cuando se usa
            // auto_return; sin ellas rechaza la preferencia.
            back_urls: {
              success: `${RETURN_URL}/success`,
              pending: `${RETURN_URL}/pending`,
              failure: `${RETURN_URL}/failure`,
            },
            auto_return: "approved",
            statement_descriptor: "CHAMPIONS RING",
          }),
        }
      );
    } catch (error) {
      logger.error("No se pudo contactar a Mercado Pago", error);
      await paymentRef.update({status: "checkout_creation_failed"});
      throw new HttpsError(
        "unavailable",
        "No fue posible conectar con Mercado Pago. Intenta de nuevo."
      );
    }

    const result = await response.json().catch(() => ({})) as {
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

      await paymentRef.update({status: "checkout_creation_failed"});

      throw new HttpsError(
        "internal",
        "No fue posible iniciar el pago."
      );
    }

    // Mercado Pago siempre devuelve ambas URLs; el servidor decide cuál
    // usar para que la app nunca mande clientes reales al sandbox.
    const checkoutUrl = USE_SANDBOX ?
      (result.sandbox_init_point ?? result.init_point) :
      result.init_point;

    await paymentRef.update({
      preferenceId: result.id,
      checkoutUrl,
    });

    return {
      paymentId: paymentRef.id,
      checkoutUrl,
    };
  }
);

// ---------------------------------------------------------------------------
// 1b. Cobro automático (suscripciones de Mercado Pago).
//     El alumno autoriza su tarjeta una vez y Mercado Pago cobra solo cada
//     7 o 30 días. Cada cobro llega al webhook como
//     subscription_authorized_payment y extiende la membresía.
// ---------------------------------------------------------------------------

interface MercadoPagoPreapproval {
  id?: string;
  status?: string;
  external_reference?: string;
  next_payment_date?: string;
  init_point?: string;
  sandbox_init_point?: string;
  message?: string;
  code?: string;
}

/**
 * Traduce los rechazos conocidos de Mercado Pago al crear una suscripción
 * en un mensaje que el alumno pueda resolver.
 *
 * @param {MercadoPagoPreapproval} response Cuerpo del error de MP.
 * @return {HttpsError} Error para devolver a la app.
 */
function subscriptionCreationError(
  response: MercadoPagoPreapproval
): HttpsError {
  const message = (response.message ?? "").toLowerCase();

  // El correo pertenece a una cuenta de Mercado Pago de otro país.
  if (
    response.code === "guest_site_mismatch" ||
    message.includes("different site") ||
    message.includes("different countries")
  ) {
    return new HttpsError(
      "failed-precondition",
      "Tu correo está ligado a una cuenta de Mercado Pago de otro país. " +
      "El cobro automático requiere una cuenta de Mercado Pago México " +
      "con el mismo correo de tu perfil."
    );
  }

  // Mezcla de credenciales de prueba con usuarios reales (o al revés).
  if (message.includes("real or test users")) {
    return new HttpsError(
      "failed-precondition",
      "La cuenta de Mercado Pago del alumno y la del gimnasio deben ser " +
      "ambas de prueba o ambas reales."
    );
  }

  if (message.includes("payer_email") || message.includes("email")) {
    return new HttpsError(
      "failed-precondition",
      "Mercado Pago no aceptó el correo de tu perfil para el cobro " +
      "automático."
    );
  }

  return new HttpsError(
    "internal",
    "No fue posible activar el cobro automático."
  );
}

export const createMembershipSubscription = onCall(
  {
    region: REGION,
    secrets: [MP_ACCESS_TOKEN],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para activar el cobro automático."
      );
    }

    const uid = request.auth.uid;
    const type: unknown = request.data?.membershipType;

    if (!isMembershipType(type) || !RECURRING_TYPES.includes(type)) {
      throw new HttpsError(
        "invalid-argument",
        "El cobro automático solo está disponible para semana y mes."
      );
    }

    const userRef = db.collection("users").doc(uid);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No existe el perfil del alumno."
      );
    }

    const userData = userSnapshot.data() ?? {};

    // La suscripción cobra siempre el mismo importe, así que la
    // inscripción debe pagarse antes con el checkout normal.
    if (userData.registration_payed !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Primero paga tu inscripción junto con tu primer periodo."
      );
    }

    if (typeof userData.email !== "string" || userData.email === "") {
      throw new HttpsError(
        "failed-precondition",
        "Tu perfil no tiene un correo registrado."
      );
    }

    if (typeof userData.subscription_id === "string") {
      const current = await db.collection("subscriptions")
        .doc(userData.subscription_id)
        .get();
      const data = current.data();

      if (data && LIVE_SUBSCRIPTION_STATUSES.includes(data.status)) {
        throw new HttpsError(
          "already-exists",
          "Ya tienes un cobro automático activo. Cancélalo para cambiar " +
          "de plan."
        );
      }

      const createdAt =
        data?.createdAt instanceof Timestamp ? data.createdAt.toMillis() : 0;

      // Igual que en el checkout: se reutiliza una autorización reciente.
      if (
        data?.status === "pending" &&
        data.membershipType === type &&
        typeof data.checkoutUrl === "string" &&
        Date.now() - createdAt < REUSE_WINDOW_MS
      ) {
        return {
          subscriptionId: current.id,
          checkoutUrl: data.checkoutUrl as string,
        };
      }
    }

    const membership = MEMBERSHIPS[type];
    const expiry = userData.membership_expires_at;
    const expiryMs = expiry instanceof Timestamp ? expiry.toMillis() : 0;

    const autoRecurring: Record<string, unknown> = {
      frequency: membership.days,
      frequency_type: "days",
      transaction_amount: membership.amount,
      currency_id: "MXN",
    };

    // Con membresía vigente, el primer cobro automático ocurre al vencer;
    // si ya venció, Mercado Pago cobra en cuanto el alumno autoriza.
    if (expiryMs > Date.now()) {
      autoRecurring.start_date = new Date(expiryMs).toISOString();
    }

    const subscriptionRef = db.collection("subscriptions").doc();

    await subscriptionRef.set({
      uid,
      membershipType: type,
      membershipPlanId: membership.planId,
      amount: membership.amount,
      currency: "MXN",
      frequencyDays: membership.days,
      status: "creating",
      provider: "mercadopago",
      createdAt: FieldValue.serverTimestamp(),
    });

    let result: {ok: boolean; status: number; data: MercadoPagoPreapproval};

    try {
      result = await mercadoPagoApi<MercadoPagoPreapproval>("/preapproval", {
        method: "POST",
        idempotencyKey: subscriptionRef.id,
        body: {
          reason: `Champions Ring - ${membership.label}`,
          external_reference: subscriptionRef.id,
          payer_email: userData.email,
          back_url: `${RETURN_URL}/subscription`,
          status: "pending",
          auto_recurring: autoRecurring,
        },
      });
    } catch (error) {
      logger.error("No se pudo contactar a Mercado Pago", error);
      await subscriptionRef.update({status: "creation_failed"});
      throw new HttpsError(
        "unavailable",
        "No fue posible conectar con Mercado Pago. Intenta de nuevo."
      );
    }

    const preapproval = result.data;

    if (!result.ok || !preapproval.id || !preapproval.init_point) {
      logger.error("Error al crear la suscripción", {
        status: result.status,
        response: preapproval,
      });
      await subscriptionRef.update({
        status: "creation_failed",
        errorCode: preapproval.code ?? null,
      });
      throw subscriptionCreationError(preapproval);
    }

    const checkoutUrl = USE_SANDBOX ?
      (preapproval.sandbox_init_point ?? preapproval.init_point) :
      preapproval.init_point;

    await subscriptionRef.update({
      preapprovalId: preapproval.id,
      checkoutUrl,
      status: "pending",
    });
    await userRef.update({
      subscription_id: subscriptionRef.id,
      subscription_status: "pending",
      subscription_membership_type: type,
      subscription_next_payment_at: FieldValue.delete(),
    });

    return {
      subscriptionId: subscriptionRef.id,
      checkoutUrl,
    };
  }
);

/**
 * Cancela una suscripción en Mercado Pago y lo refleja en Firestore.
 *
 * @param {string} subscriptionId Documento en subscriptions.
 * @param {string} preapprovalId Identificador de Mercado Pago.
 * @param {string} reason Motivo guardado para auditoría.
 */
async function cancelPreapproval(
  subscriptionId: string,
  preapprovalId: string,
  reason: string
): Promise<void> {
  const result = await mercadoPagoApi<MercadoPagoPreapproval>(
    `/preapproval/${encodeURIComponent(preapprovalId)}`,
    {method: "PUT", body: {status: "cancelled"}}
  );

  if (!result.ok && result.status !== 404) {
    logger.error("Mercado Pago no canceló la suscripción", {
      status: result.status,
      subscriptionId,
      response: result.data,
    });
    throw new Error("No se pudo cancelar la suscripción.");
  }

  await db.collection("subscriptions").doc(subscriptionId).update({
    status: "cancelled",
    cancelReason: reason,
    cancelledAt: FieldValue.serverTimestamp(),
  });
}

export const cancelMembershipSubscription = onCall(
  {
    region: REGION,
    secrets: [MP_ACCESS_TOKEN],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const userRef = db.collection("users").doc(request.auth.uid);
    const userData = (await userRef.get()).data() ?? {};
    const subscriptionId = userData.subscription_id;

    if (typeof subscriptionId !== "string") {
      throw new HttpsError(
        "failed-precondition",
        "No tienes un cobro automático activo."
      );
    }

    const subscription =
      (await db.collection("subscriptions").doc(subscriptionId).get())
        .data();

    if (
      subscription &&
      typeof subscription.preapprovalId === "string" &&
      subscription.status !== "cancelled"
    ) {
      try {
        await cancelPreapproval(
          subscriptionId,
          subscription.preapprovalId,
          "user_request"
        );
      } catch {
        throw new HttpsError(
          "unavailable",
          "No fue posible cancelar con Mercado Pago. Intenta de nuevo."
        );
      }
    }

    // La membresía ya pagada sigue vigente hasta su vencimiento.
    await userRef.update({
      subscription_status: "cancelled",
      subscription_next_payment_at: FieldValue.delete(),
    });

    return {status: "cancelled"};
  }
);

// La app la llama mientras ve la autorización "pendiente": consulta el
// estado directamente en Mercado Pago, por si el aviso del webhook no llegó.
export const syncMembershipSubscription = onCall(
  {
    region: REGION,
    secrets: [MP_ACCESS_TOKEN],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const userRef = db.collection("users").doc(request.auth.uid);
    const subscriptionId = (await userRef.get()).data()?.subscription_id;

    if (typeof subscriptionId !== "string") return {status: null};

    const subscription =
      (await db.collection("subscriptions").doc(subscriptionId).get())
        .data();

    if (!subscription || typeof subscription.preapprovalId !== "string") {
      return {status: subscription?.status ?? null};
    }

    try {
      await handlePreapprovalNotification(subscription.preapprovalId);
    } catch (error) {
      logger.error("No se pudo sincronizar la suscripción", error);
      throw new HttpsError(
        "unavailable",
        "No fue posible consultar Mercado Pago. Intenta de nuevo."
      );
    }

    return {status: (await userRef.get()).data()?.subscription_status ?? null};
  }
);

// ---------------------------------------------------------------------------
// 2. Página a la que Mercado Pago regresa al usuario después de pagar.
//    Es solo informativa: la membresía se activa por el webhook.
// ---------------------------------------------------------------------------

const RETURN_MESSAGES: Record<string, {title: string; body: string}> = {
  success: {
    title: "¡Gracias por tu pago!",
    body: "Estamos confirmando tu pago. Tu membresía se activará en " +
      "unos momentos. Ya puedes volver a la app Champions Ring.",
  },
  pending: {
    title: "Tu pago está pendiente",
    body: "Cuando Mercado Pago lo confirme, activaremos tu membresía. " +
      "Ya puedes volver a la app Champions Ring.",
  },
  failure: {
    title: "No se completó el pago",
    body: "No se realizó ningún cargo. Vuelve a la app Champions Ring " +
      "para intentarlo de nuevo.",
  },
  subscription: {
    title: "Cobro automático",
    body: "Cuando Mercado Pago confirme la autorización de tu tarjeta, " +
      "verás el cobro automático activo en la app Champions Ring.",
  },
};

// invoker "public": la abre el navegador del cliente al volver de
// Mercado Pago; sin esto Cloud Run responde 403.
export const paymentReturn = onRequest(
  {region: REGION, invoker: "public"},
  (req, res) => {
    const key = req.path.replace(/^\/+|\/+$/g, "");
    const message = RETURN_MESSAGES[key] ?? RETURN_MESSAGES.pending;

    // No se imprime ningún dato de la URL: solo textos fijos.
    res
      .status(200)
      .set("Cache-Control", "no-store")
      .set(
        "Content-Security-Policy",
        "default-src 'none'; style-src 'unsafe-inline'"
      )
      .type("html")
      .send(
        "<!doctype html><html lang=\"es\"><head>" +
        "<meta charset=\"utf-8\">" +
        "<meta name=\"viewport\" content=\"width=device-width," +
        "initial-scale=1\">" +
        "<title>Champions Ring</title>" +
        "<style>body{font-family:system-ui,sans-serif;display:flex;" +
        "min-height:100vh;margin:0;align-items:center;" +
        "justify-content:center;background:#fff;color:#1a1a1a}" +
        "main{max-width:360px;padding:24px;text-align:center}" +
        "h1{color:#ea3a3f;font-size:24px}p{line-height:1.5}</style>" +
        "</head><body><main>" +
        `<h1>${message.title}</h1><p>${message.body}</p>` +
        "</main></body></html>"
      );
  }
);

// ---------------------------------------------------------------------------
// 3. Webhook de Mercado Pago
// ---------------------------------------------------------------------------

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

  const expected = createHmac("sha256", secret)
    .update(manifest)
    .digest("hex");

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
    transaction_data?: {subscription_id?: string; invoice_id?: string | number};
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
  mpPaymentId: string
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
  payment: MercadoPagoPayment
): Promise<WebhookOutcome | null> {
  const mpPaymentId = String(payment.id);
  const matches = await db.collection("payments")
    .where("mercadoPagoPaymentId", "==", mpPaymentId)
    .limit(5)
    .get();
  const charge = matches.docs.find(
    (doc) => doc.data().source === "subscription"
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
    }
  );

  if (outcome === "reversal_recorded") {
    logger.warn("Reversión de un cobro automático", {
      paymentId: charge.id,
      mpPaymentId,
      status: payment.status,
    });
    await stopSubscriptionAfterChargeback(
      payment.status,
      charge.data().subscriptionId
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
  subscriptionId: unknown
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

interface MercadoPagoAuthorizedPayment {
  id?: number | string;
  preapproval_id?: string;
  transaction_amount?: number;
  currency_id?: string;
  status?: string;
  payment?: {id?: number | string; status?: string};
}

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
    `/preapproval/${encodeURIComponent(preapprovalId)}`
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
async function handlePreapprovalNotification(
  preapprovalId: string
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
  authorizedPaymentId: string
): Promise<string> {
  const result = await mercadoPagoApi<MercadoPagoAuthorizedPayment>(
    `/authorized_payments/${encodeURIComponent(authorizedPaymentId)}`
  );

  if (result.status === 404) return "unknown_payment";
  if (!result.ok) {
    throw new Error(
      `Mercado Pago respondió ${result.status} (authorized_payments)`
    );
  }

  const charge = result.data;
  if (!charge.preapproval_id) return "unknown_subscription";

  const loaded = await loadPreapproval(charge.preapproval_id);
  if (!loaded) return "unknown_subscription";

  const {subscriptionRef} = loaded;
  const paymentRef = db.collection("payments")
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
        tx.update(paymentRef, reversalUpdate(
          paymentStatus,
          String(charge.payment?.id ?? storedCharge.mercadoPagoPaymentId)
        ));
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
    tx.set(paymentRef, {
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
    }, {merge: true});

    if (!approved) return "recorded";

    tx.update(userRef, {
      ...membershipActivation(
        stored.membershipType,
        userSnapshot.data()?.membership_expires_at
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
      notificationType
    ) ?
      SUBSCRIPTION_HANDLERS[notificationType] :
      undefined;

    if (notificationType !== "payment" && !subscriptionHandler) {
      res.status(200).send("Ignored notification type");
      return;
    }

    const dataId = firstValue(req.query["data.id"]) ??
      firstValue(req.body?.data?.id) ??
      "";
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
        }
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

      const payment = await mpResponse.json() as MercadoPagoPayment;

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
        const outcome =
          await handleAuthorizedPaymentNotification(String(invoiceId));
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
              Number(payment.transaction_amount) - Number(stored.amount)
            ) > 0.009
          ) {
            return "mismatch";
          }

          if (stored.processed === true) {
            // Ya activada: solo se registran reembolsos o contracargos.
            if (REVERSAL_STATUSES.includes(payment.status)) {
              tx.update(
                paymentRef,
                reversalUpdate(payment.status, mpPaymentId)
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
              userSnapshot.data()?.membership_expires_at
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
        }
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
  }
);
