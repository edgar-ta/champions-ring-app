import type {
  DocumentData,
  DocumentReference,
} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "../utils/firestore_entity.js";
import {
  readDate,
  readNumber,
  readOptionalDate,
  readReference,
  readUid,
} from "../utils/firestore_values.js";

/** Renovación de membresía almacenada en renewals dentro de members. */
export class CoreRenewal extends FirestoreEntity {
  /** Crea una renovación de membresía. */
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
   * Convierte esta renovación al formato de Firestore.
   * @return {DocumentData} Datos del documento de Firestore.
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
   * Crea una renovación a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} [documentId] ID alternativo del documento.
   * @return {CoreRenewal} Renovación decodificada.
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
