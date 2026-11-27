import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "../utils/firestore_entity.js";
import {
  readDate,
  readEnum,
  readNumber,
  readOptionalDate,
  readString,
  readUid,
} from "../utils/firestore_values.js";

/** Duraciones admitidas para los planes de membresía. */
export const CORE_MEMBERSHIP_PLAN_DURATIONS = ["1d", "1w", "1m"] as const;
export type CoreMembershipPlanDuration =
  typeof CORE_MEMBERSHIP_PLAN_DURATIONS[number];

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * Plan de membresía almacenado en la colección membership_plans.
 */
export class CoreMembershipPlan extends FirestoreEntity {
  /** Crea un plan de membresía. */
  constructor(
    readonly uid: string,
    readonly cost: number,
    readonly benefits: string,
    readonly duration: CoreMembershipPlanDuration,
    readonly creationDate: CoreDate,
    readonly name: string,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Convierte este plan al formato de Firestore.
   * @return {DocumentData} Datos del documento de Firestore.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      cost: this.cost,
      benefits: this.benefits,
      duration: this.duration,
      creationDate: this.creationDate.toFirebaseValue(),
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Crea un plan de membresía a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} [documentId] ID alternativo del documento.
   * @return {CoreMembershipPlan} Plan de membresía decodificado.
   */
  static fromFirestore(
    data: DocumentData,
    documentId?: string
  ): CoreMembershipPlan {
    return new CoreMembershipPlan(
      readUid(data, documentId),
      readNumber(data, "cost", "amount"),
      readString(data, "benefits"),
      readEnum(data, "duration", CORE_MEMBERSHIP_PLAN_DURATIONS),
      readDate(data, "creationDate"),
      readString(data, "name"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
