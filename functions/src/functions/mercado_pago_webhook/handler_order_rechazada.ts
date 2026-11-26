import {logger} from "firebase-functions";
import {db} from "../../core/utils/constants.js";
import {
  CorePaymentRepository,
} from "../../core/repositories/core_payment_repository.js";
import type {MercadoPagoOrder} from "../../shared/models/register_order.js";
import {getPaymentUid} from "../../shared/utils/register_order.js";

/**
 * Aplica el protocolo 4 y guarda el detalle de rechazo de la order.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderRechazada(
  order: MercadoPagoOrder,
): Promise<void> {
  try {
    if (typeof order.status_detail !== "string") {
      throw new TypeError("La order rechazada no incluye status_detail.");
    }
    const paymentUid = getPaymentUid(order);
    const paymentRepository = new CorePaymentRepository(db);
    const payment = await paymentRepository.findById(paymentUid);
    if (!payment) {
      throw new Error(`El pago "${paymentUid}" no existe.`);
    }
    await paymentRepository.updateStatus(paymentUid, "rejected");
    await paymentRepository.collection.doc(paymentUid).update({
      rejectionDetail: order.status_detail,
    });
  } catch (error) {
    logger.error("No se pudo rechazar el pago de la order.", error);
    throw error;
  }
}
