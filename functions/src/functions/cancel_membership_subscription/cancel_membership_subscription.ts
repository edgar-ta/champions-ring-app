import {logger} from "firebase-functions";
import {FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {MP_ACCESS_TOKEN, REGION, db} from "../../core/utils/constants.js";
import {
  mercadoPagoApi,
  type MercadoPagoPreapproval,
} from "../../shared/utils/shared.js";

/**
 * Cancela una autorización de Mercado Pago y actualiza su documento
 * en Firestore.
 *
 * @param {string} subscriptionId ID del documento de suscripción en Firestore.
 * @param {string} preapprovalId ID de la autorización en Mercado Pago.
 * @param {string} reason Motivo de cancelación que se guardará para auditoría.
 */
export async function cancelPreapproval(
  subscriptionId: string,
  preapprovalId: string,
  reason: string,
): Promise<void> {
  const result = await mercadoPagoApi<MercadoPagoPreapproval>(
    `/preapproval/${encodeURIComponent(preapprovalId)}`,
    {method: "PUT", body: {status: "cancelled"}},
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
        "No tienes un cobro automático activo.",
      );
    }

    const subscription = (
      await db.collection("subscriptions").doc(subscriptionId).get()
    ).data();

    if (
      subscription &&
      typeof subscription.preapprovalId === "string" &&
      subscription.status !== "cancelled"
    ) {
      try {
        await cancelPreapproval(
          subscriptionId,
          subscription.preapprovalId,
          "user_request",
        );
      } catch {
        throw new HttpsError(
          "unavailable",
          "No fue posible cancelar con Mercado Pago. Intenta de nuevo.",
        );
      }
    }

    // La membresía ya pagada sigue vigente hasta su vencimiento.
    await userRef.update({
      subscription_status: "cancelled",
      subscription_next_payment_at: FieldValue.delete(),
    });

    return {status: "cancelled"};
  },
);

