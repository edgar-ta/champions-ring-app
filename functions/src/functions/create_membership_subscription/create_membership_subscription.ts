import {logger} from "firebase-functions";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  LIVE_SUBSCRIPTION_STATUSES,
  MEMBERSHIPS,
  MP_ACCESS_TOKEN,
  REGION,
  RECURRING_TYPES,
  REUSE_WINDOW_MS,
  RETURN_URL,
  USE_SANDBOX,
  db,
} from "../../core/utils/constants.js";
import {
  isMembershipType,
  mercadoPagoApi,
  type MercadoPagoPreapproval,
} from "../../shared/utils/shared.js";

/**
 * Traduce los rechazos conocidos de Mercado Pago al crear una suscripción
 * en un mensaje que el alumno pueda resolver.
 *
 * @param {MercadoPagoPreapproval} response Cuerpo del error de MP.
 * @return {HttpsError} Error para devolver a la app.
 */
function subscriptionCreationError(
  response: MercadoPagoPreapproval,
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
        "con el mismo correo de tu perfil.",
    );
  }

  // Mezcla de credenciales de prueba con usuarios reales (o al revés).
  if (message.includes("real or test users")) {
    return new HttpsError(
      "failed-precondition",
      "La cuenta de Mercado Pago del alumno y la del gimnasio deben ser " +
        "ambas de prueba o ambas reales.",
    );
  }

  if (message.includes("payer_email") || message.includes("email")) {
    return new HttpsError(
      "failed-precondition",
      "Mercado Pago no aceptó el correo de tu perfil para el cobro " +
        "automático.",
    );
  }

  return new HttpsError(
    "internal",
    "No fue posible activar el cobro automático.",
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
        "Debes iniciar sesión para activar el cobro automático.",
      );
    }

    const uid = request.auth.uid;
    const type: unknown = request.data?.membershipType;

    if (!isMembershipType(type) || !RECURRING_TYPES.includes(type)) {
      throw new HttpsError(
        "invalid-argument",
        "El cobro automático solo está disponible para semana y mes.",
      );
    }

    const userRef = db.collection("users").doc(uid);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No existe el perfil del alumno.",
      );
    }

    const userData = userSnapshot.data() ?? {};

    // La suscripción cobra siempre el mismo importe, así que la
    // inscripción debe pagarse antes con el checkout normal.
    if (userData.registration_payed !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Primero paga tu inscripción junto con tu primer periodo.",
      );
    }

    if (typeof userData.email !== "string" || userData.email === "") {
      throw new HttpsError(
        "failed-precondition",
        "Tu perfil no tiene un correo registrado.",
      );
    }

    if (typeof userData.subscription_id === "string") {
      const current = await db
        .collection("subscriptions")
        .doc(userData.subscription_id)
        .get();
      const data = current.data();

      if (data && LIVE_SUBSCRIPTION_STATUSES.includes(data.status)) {
        throw new HttpsError(
          "already-exists",
          "Ya tienes un cobro automático activo. Cancélalo para cambiar " +
            "de plan.",
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

    let result: { ok: boolean; status: number; data: MercadoPagoPreapproval };

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
        "No fue posible conectar con Mercado Pago. Intenta de nuevo.",
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
  },
);
