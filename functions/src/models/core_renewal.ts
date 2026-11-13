import type {
  DocumentData,
  DocumentReference,
} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readDate,
  readNumber,
  readOptionalDate,
  readReference,
  readUid,
} from "./firestore_values.js";

/** Membership renewal stored under a member's renewals subcollection. */
export class CoreRenewal extends FirestoreEntity {
  /** Creates a membership renewal. */
  constructor(
    readonly uid: string,
    readonly startDate: CoreDate,
    readonly endDate: CoreDate,
    readonly paymentRef: DocumentReference,
    readonly amount: number,
    readonly creationDate: CoreDate,
    readonly membershipPlanRef: DocumentReference,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Converts this renewal to its Firestore representation.
   * @return {DocumentData} Firestore document data.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      startDate: this.startDate.toFirebaseValue(),
      endDate: this.endDate.toFirebaseValue(),
      paymentRef: this.paymentRef,
      amount: this.amount,
      creationDate: this.creationDate.toFirebaseValue(),
      membershipPlanRef: this.membershipPlanRef,
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Creates a renewal from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreRenewal} Decoded renewal.
   */
  static fromFirestore(data: DocumentData, documentId?: string): CoreRenewal {
    return new CoreRenewal(
      readUid(data, documentId),
      readDate(data, "startDate"),
      readDate(data, "endDate"),
      readReference(data, "paymentRef"),
      readNumber(data, "amount"),
      readDate(data, "creationDate"),
      readReference(data, "membershipPlanRef"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
