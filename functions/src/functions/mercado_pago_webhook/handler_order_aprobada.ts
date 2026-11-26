import type {DocumentReference} from "firebase-admin/firestore";
import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {
  db,
  INSCRIPTION_PRODUCT_ID,
} from "../../core/utils/constants.js";
import {
  CorePaymentRepository,
} from "../../core/repositories/core_payment_repository.js";
import type {MercadoPagoOrder} from "../../shared/models/register_order.js";
import {getPaymentUid} from "../../shared/utils/register_order.js";

/**
 * Aplica el protocolo 1 y marca como pagada la inscripción, si corresponde.
 * @param {MercadoPagoOrder} order Order vigente obtenida de Mercado Pago.
 * @return {Promise<void>} Se resuelve al guardar los cambios.
 * @see docs/dev-team/integracion-con-mercado-pago.md
 */
export async function handlerOrderAprobada(
  order: MercadoPagoOrder,
): Promise<void> {
  try {
    const paymentUid = getPaymentUid(order);
    const paymentRepository = new CorePaymentRepository(db);
    const payment = await paymentRepository.findById(paymentUid);
    if (!payment) {
      throw new Error(`El pago "${paymentUid}" no existe.`);
    }

    let memberRef: DocumentReference | undefined;
    const includesInscription = order.items?.some(
      (item) => item.external_code === INSCRIPTION_PRODUCT_ID,
    ) ?? false;
    if (includesInscription) {
      if (!payment.payerRef) {
        throw new Error("El pago de inscripción debe incluir payerRef.");
      }
      const memberId = payment.payerRef.path.split("/").pop();
      if (!memberId) {
        throw new Error("No se pudo determinar el miembro asociado al pago.");
      }

      memberRef = db.collection("members").doc(memberId);
      const memberSnapshot = await memberRef.get();
      if (!memberSnapshot.exists) {
        throw new Error(`No existe el miembro "${memberId}" asociado al pago.`);
      }
    }

    await paymentRepository.updateStatus(paymentUid, "approved");
    const batch = db.batch();
    batch.update(
      paymentRepository.collection.doc(paymentUid),
      {approvalDate: FieldValue.serverTimestamp()},
    );
    if (memberRef) {
      batch.update(memberRef, {inscriptionPaid: true});
    }
    await batch.commit();
  } catch (error) {
    logger.error("No se pudo aprobar el pago de la order.", error);
    throw error;
  }
}
