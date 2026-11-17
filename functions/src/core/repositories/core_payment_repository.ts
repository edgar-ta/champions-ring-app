import type {
  DocumentData,
  Firestore,
} from "firebase-admin/firestore";
import {CorePayment} from "../models/core_payment.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de pagos. */
export class CorePaymentRepository extends BaseRepository<CorePayment> {
  /**
   * Crea un repositorio de pagos.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección payments de Firestore. */
  protected get collectionPath(): string {
    return "payments";
  }

  /**
   * Crea un pago a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CorePayment} Pago decodificado.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CorePayment {
    return CorePayment.fromFirestore(data, documentId);
  }

  /**
   * Valida las referencias del pago y guarda el documento en una transacción.
   * @param {CorePayment} payment Pago que se guardará.
   * @return {Promise<boolean>} Indica si se creó el pago.
   */
  override async upsert(payment: CorePayment): Promise<boolean> {
    if (!Number.isFinite(payment.amount) || payment.amount <= 0) {
      throw new RangeError("payment.amount must be greater than zero.");
    }

    if (
      payment.approverRef !== undefined &&
      payment.approverRef.parent.path !== "receptionists"
    ) {
      throw new TypeError(
        "payment.approverRef must reference a \"receptionists\" document."
      );
    }
    if (
      payment.payerRef !== undefined &&
      payment.payerRef.parent.path !== "clients"
    ) {
      throw new TypeError(
        "payment.payerRef must reference a \"clients\" document."
      );
    }

    const paymentDocument = this.collection.doc(payment.uid);
    return this.firestore.runTransaction(async (transaction) => {
      const approverSnapshot = payment.approverRef ?
        await transaction.get(payment.approverRef) :
        undefined;
      const paymentSnapshot = await transaction.get(paymentDocument);

      if (approverSnapshot && !approverSnapshot.exists) {
        throw new Error(
          `Receptionist "${payment.approverRef?.id}" referenced by payment ` +
          `"${payment.uid}" was not found.`
        );
      }

      transaction.set(paymentDocument, payment.toFirestore());
      return !paymentSnapshot.exists;
    });
  }
}
