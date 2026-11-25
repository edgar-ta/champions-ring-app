import type {MercadoPagoOrder} from "../../shared/utils/register_order.js";

export type OrderHandler = (order: MercadoPagoOrder) => Promise<void>;

/**
 * Obtiene y valida el UID del pago asociado a la order.
 * @param {MercadoPagoOrder} order Order vigente de Mercado Pago.
 * @return {string} UID del pago asociado.
 */
export function getPaymentUid(order: MercadoPagoOrder): string {
  const paymentUid = order.external_reference;
  if (
    typeof paymentUid !== "string" ||
    paymentUid.trim() === "" ||
    paymentUid.includes("/")
  ) {
    throw new TypeError("La order no incluye una referencia externa válida.");
  }
  return paymentUid;
}
