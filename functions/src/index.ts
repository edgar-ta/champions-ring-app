import {logger} from "firebase-functions";
import {getAuth} from "firebase-admin/auth";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {EMAIL_PATTERN, REGION} from "./core/utils/constants.js";

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
      if ((error as { code?: string }).code === "auth/user-not-found") {
        return {available: true};
      }
      logger.error("No se pudo verificar el correo", error);
      throw new HttpsError("internal", "No se pudo verificar el correo.");
    }
  },
);
export {createPaymentCheckout} from "./functions/create_payment_checkout.js";
export {
  paymentReturn,
} from "./functions/payment_return.js";

export {
  mercadoPagoWebhook,
} from "./functions/mercado_pago_webhook.js";
