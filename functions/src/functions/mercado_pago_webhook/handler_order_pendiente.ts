import {logger} from "firebase-functions";
import {db} from "../../core/utils/constants.js";
import {
  CorePaymentRepository,
} from "../../core/repositories/core_payment_repository.js";
import type {MercadoPagoOrder} from "../../shared/models/register_order.js";
import {getPaymentUid} from "../../shared/utils/register_order.js";

/**
 * Aplica el protocolo 2 y marca el pago como processing.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderPendiente(
  order: MercadoPagoOrder,
): Promise<void> {
  try {
    const paymentUid = getPaymentUid(order);
    const paymentRepository = new CorePaymentRepository(db);
    const payment = await paymentRepository.findById(paymentUid);
    if (!payment) {
      throw new Error(`El pago "${paymentUid}" no existe.`);
    }
    await paymentRepository.updateStatus(paymentUid, "processing");
  } catch (error) {
    logger.error("No se pudo actualizar el estado pendiente del pago.", error);
    throw error;
  }
}
