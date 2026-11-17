import {logger} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {MP_ACCESS_TOKEN, REGION, db} from "../../core/utils/constants.js";
import {
  handlePreapprovalNotification,
} from "../mercado_pago_webhook/mercado_pago_webhook.js";

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

    const subscription = (
      await db.collection("subscriptions").doc(subscriptionId).get()
    ).data();

    if (!subscription || typeof subscription.preapprovalId !== "string") {
      return {status: subscription?.status ?? null};
    }

    try {
      await handlePreapprovalNotification(subscription.preapprovalId);
    } catch (error) {
      logger.error("No se pudo sincronizar la suscripción", error);
      throw new HttpsError(
        "unavailable",
        "No fue posible consultar Mercado Pago. Intenta de nuevo.",
      );
    }

    return {
      status: (await userRef.get()).data()?.subscription_status ?? null,
    };
  },
);

// ---------------------------------------------------------------------------
// 2. Página a la que Mercado Pago regresa al usuario después de pagar.
//    Es solo informativa: la membresía se activa por el webhook.
// ---------------------------------------------------------------------------
