import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readDate,
  readEnum,
  readNumber,
  readOptionalDate,
  readOptionalString,
  readString,
  readUid,
} from "./firestore_values.js";

/** Supported membership plan durations. */
export const CORE_MEMBERSHIP_PLAN_DURATIONS = ["1d", "1w", "1m"] as const;
export type CoreMembershipPlanDuration =
  typeof CORE_MEMBERSHIP_PLAN_DURATIONS[number];

/** Membership plan stored in the membership_plans collection. */
export class CoreMembershipPlan extends FirestoreEntity {
  /** Creates a membership plan. */
  constructor(
    readonly uid: string,
    readonly cost: number,
    readonly benefits: string,
    readonly duration: CoreMembershipPlanDuration,
    readonly creationDate: CoreDate,
    readonly name?: string,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Converts this plan to its Firestore representation.
   * @return {DocumentData} Firestore document data.
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
   * Creates a membership plan from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreMembershipPlan} Decoded membership plan.
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
      readOptionalString(data, "name"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
