import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  CORE_SUBSCRIPTION_MEMBERSHIP_TYPES,
  type CoreSubscriptionMembershipType,
} from "./core_payment.js";
import {
  readDate,
  readEnum,
  readNumber,
  readOptionalDate,
  readOptionalString,
  readUid,
} from "./firestore_values.js";

/** Supported states of a recurring subscription. */
export const CORE_SUBSCRIPTION_STATUSES = [
  "creating",
  "creation_failed",
  "pending",
  "authorized",
  "paused",
  "cancelled",
] as const;
export type CoreSubscriptionStatus =
  typeof CORE_SUBSCRIPTION_STATUSES[number];

/** Recurring membership subscription stored in the subscriptions collection. */
export class CoreSubscription extends FirestoreEntity {
  /** Creates a recurring subscription. */
  constructor(
    readonly uid: string,
    readonly membershipType: CoreSubscriptionMembershipType,
    readonly membershipPlanId: number,
    readonly amount: number,
    readonly frequencyDays: number,
    readonly status: CoreSubscriptionStatus,
    readonly createdAt: CoreDate,
    readonly currency: "MXN" = "MXN",
    readonly preapprovalId?: string,
    readonly checkoutUrl?: string,
    readonly nextPaymentAt?: CoreDate
  ) {
    super();
  }

  /**
   * Converts this subscription to its Firestore representation.
   * @return {DocumentData} Firestore document data.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      membershipType: this.membershipType,
      membershipPlanId: this.membershipPlanId,
      amount: this.amount,
      currency: this.currency,
      frequencyDays: this.frequencyDays,
      status: this.status,
      createdAt: this.createdAt.toFirebaseValue(),
      ...(this.preapprovalId !== undefined ?
        {preapprovalId: this.preapprovalId} :
        {}),
      ...(this.checkoutUrl !== undefined ?
        {checkoutUrl: this.checkoutUrl} :
        {}),
      ...(this.nextPaymentAt ?
        {nextPaymentAt: this.nextPaymentAt.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Creates a subscription from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreSubscription} Decoded subscription.
   */
  static fromFirestore(
    data: DocumentData,
    documentId?: string
  ): CoreSubscription {
    return new CoreSubscription(
      readUid(data, documentId),
      readEnum(
        data,
        "membershipType",
        CORE_SUBSCRIPTION_MEMBERSHIP_TYPES
      ),
      readNumber(data, "membershipPlanId"),
      readNumber(data, "amount"),
      readNumber(data, "frequencyDays"),
      readEnum(data, "status", CORE_SUBSCRIPTION_STATUSES),
      readDate(data, "createdAt"),
      readEnum(data, "currency", ["MXN"]),
      readOptionalString(data, "preapprovalId"),
      readOptionalString(data, "checkoutUrl"),
      readOptionalDate(data, "nextPaymentAt")
    );
  }
}
