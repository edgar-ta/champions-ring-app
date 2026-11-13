import type {
  DocumentData,
  Firestore,
} from "firebase-admin/firestore";
import {CorePayment} from "../models/core_payment.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for payments. */
export class CorePaymentRepository extends BaseRepository<CorePayment> {
  /**
   * Creates a payment repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore payments collection. */
  protected get collectionPath(): string {
    return "payments";
  }

  /**
   * Builds a payment from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CorePayment} Decoded payment.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CorePayment {
    return CorePayment.fromFirestore(data, documentId);
  }

  /**
   * Validates payment references and saves the document transactionally.
   * @param {CorePayment} payment Payment to save.
   * @return {Promise<boolean>} True when the payment was created.
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
