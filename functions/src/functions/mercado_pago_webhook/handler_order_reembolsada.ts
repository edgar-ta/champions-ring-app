import {logger} from "firebase-functions";
import {db} from "../../core/utils/constants.js";
import {
  CorePaymentRepository,
} from "../../core/repositories/core_payment_repository.js";
import type {MercadoPagoOrder} from "../../shared/models/register_order.js";
import {getPaymentUid} from "../../shared/utils/register_order.js";

/**
 * Aplica el protocolo 3 y marca el pago como refunded.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderReembolsada(
  order: MercadoPagoOrder,
): Promise<void> {
  try {
    const paymentUid = getPaymentUid(order);
    const paymentRepository = new CorePaymentRepository(db);
    const payment = await paymentRepository.findById(paymentUid);
    if (!payment) {
      throw new Error(`El pago "${paymentUid}" no existe.`);
    }
    await paymentRepository.updateStatus(paymentUid, "refunded");
  } catch (error) {
    logger.error("No se pudo reembolsar el pago de la order.", error);
    throw error;
  }
}
