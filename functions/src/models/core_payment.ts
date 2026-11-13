import type {
  DocumentData,
  DocumentReference,
} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readDate,
  readEnum,
  readNumber,
  readOptionalDate,
  readOptionalReference,
  readOptionalString,
  readUid,
} from "./firestore_values.js";

/** Supported payment types. */
export const CORE_PAYMENT_TYPES = [
  "cash",
  "direct-transfer",
  "mercado-pago",
] as const;
export type CorePaymentType = typeof CORE_PAYMENT_TYPES[number];

/** Supported payment currencies. */
export const CORE_PAYMENT_CURRENCIES = ["MXN", "USD"] as const;
export type CorePaymentCurrency = typeof CORE_PAYMENT_CURRENCIES[number];

/** Payment states used by the app and Mercado Pago functions. */
export const CORE_PAYMENT_STATUSES = [
  "pending",
  "approved",
  "rejected",
  "checkout_creation_failed",
  "authorized",
  "in_process",
  "in_mediation",
  "cancelled",
  "refunded",
  "charged_back",
  "expired",
] as const;
export type CorePaymentStatus = typeof CORE_PAYMENT_STATUSES[number];

/** Bank issuers supported by direct-transfer payments. */
export const CORE_PAYMENT_ISSUING_ENTITIES = [
  "bbva",
  "santander",
  "banco-azteca",
  "elektra",
  "other",
] as const;
export type CorePaymentIssuingEntity =
  typeof CORE_PAYMENT_ISSUING_ENTITIES[number];

/** Membership durations allowed for recurring payments. */
export const CORE_SUBSCRIPTION_MEMBERSHIP_TYPES = ["week", "month"] as const;
export type CoreSubscriptionMembershipType =
  typeof CORE_SUBSCRIPTION_MEMBERSHIP_TYPES[number];
export const CORE_PAYMENT_SUBSCRIPTION_STATUSES = [
  "pending",
  "authorized",
  "paused",
  "cancelled",
] as const;
export type CorePaymentSubscriptionStatus =
  typeof CORE_PAYMENT_SUBSCRIPTION_STATUSES[number];

/** Payment document matching the payments collection schema. */
export class CorePayment extends FirestoreEntity {
  /** Creates a payment. */
  constructor(
    readonly uid: string,
    readonly type: CorePaymentType,
    readonly amount: number,
    readonly currency: CorePaymentCurrency,
    readonly creationDate: CoreDate,
    readonly approvalDate?: CoreDate,
    readonly payerRef?: DocumentReference,
    readonly checkoutUrl?: string,
    readonly status?: CorePaymentStatus,
    readonly mercadoPagoPaymentId?: string,
    readonly preferenceId?: string,
    readonly subscriptionId?: string,
    readonly subscriptionStatus?: CorePaymentSubscriptionStatus,
    readonly subscriptionMembershipType?: CoreSubscriptionMembershipType,
    readonly subscriptionNextPaymentAt?: CoreDate,
    readonly referenceId?: string,
    readonly issuingEntity?: CorePaymentIssuingEntity,
    readonly issuingEntityName?: string,
    readonly approverRef?: DocumentReference,
    readonly deletionDate?: CoreDate,
    readonly source?: "subscription"
  ) {
    super();
  }

  /**
   * Converts this payment to its Firestore representation.
   * @return {DocumentData} Firestore document data.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      type: this.type,
      amount: this.amount,
      currency: this.currency,
      creationDate: this.creationDate.toFirebaseValue(),
      ...(this.approvalDate ?
        {approvalDate: this.approvalDate.toFirebaseValue()} :
        {}),
      ...(this.payerRef ? {payerRef: this.payerRef} : {}),
      ...(this.checkoutUrl !== undefined ?
        {checkoutUrl: this.checkoutUrl} :
        {}),
      ...(this.status !== undefined ? {status: this.status} : {}),
      ...(this.mercadoPagoPaymentId !== undefined ?
        {mercadoPagoPaymentId: this.mercadoPagoPaymentId} :
        {}),
      ...(this.preferenceId !== undefined ?
        {preferenceId: this.preferenceId} :
        {}),
      ...(this.subscriptionId !== undefined ?
        {subscription_id: this.subscriptionId} :
        {}),
      ...(this.subscriptionStatus !== undefined ?
        {subscription_status: this.subscriptionStatus} :
        {}),
      ...(this.subscriptionMembershipType !== undefined ?
        {subscription_membership_type: this.subscriptionMembershipType} :
        {}),
      ...(this.subscriptionNextPaymentAt ?
        {subscription_next_payment_at:
          this.subscriptionNextPaymentAt.toFirebaseValue()} :
        {}),
      ...(this.referenceId !== undefined ?
        {referenceId: this.referenceId} :
        {}),
      ...(this.issuingEntity !== undefined ?
        {issuingEntity: this.issuingEntity} :
        {}),
      ...(this.issuingEntityName !== undefined ?
        {issuingEntityName: this.issuingEntityName} :
        {}),
      ...(this.approverRef ? {approverRef: this.approverRef} : {}),
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
      ...(this.source !== undefined ? {source: this.source} : {}),
    };
  }

  /**
   * Creates a payment from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CorePayment} Decoded payment.
   */
  static fromFirestore(data: DocumentData, documentId?: string): CorePayment {
    return new CorePayment(
      readUid(data, documentId),
      readPaymentType(data),
      readNumber(data, "amount"),
      readEnum(data, "currency", CORE_PAYMENT_CURRENCIES),
      readDate(data, "creationDate", "createdAt"),
      readOptionalDate(data, "approvalDate", "approvedAt"),
      readOptionalReference(data, "payerRef"),
      readOptionalString(data, "checkoutUrl"),
      readOptionalPaymentStatus(data),
      readOptionalString(data, "mercadoPagoPaymentId"),
      readOptionalString(data, "preferenceId"),
      readOptionalString(data, "subscription_id", "subscriptionId"),
      readOptionalSubscriptionStatus(data),
      readOptionalSubscriptionType(data),
      readOptionalDate(
        data,
        "subscription_next_payment_at",
        "subscriptionNextPaymentAt"
      ),
      readOptionalString(data, "referenceId"),
      readOptionalIssuingEntity(data),
      readOptionalString(data, "issuingEntityName"),
      readOptionalReference(data, "approverRef"),
      readOptionalDate(data, "deletionDate"),
      readOptionalSource(data)
    );
  }
}

/**
 * Reads a payment type and infers the legacy Mercado Pago type when needed.
 * @param {DocumentData} data Firestore document data.
 * @return {CorePaymentType} Payment type.
 */
function readPaymentType(data: DocumentData): CorePaymentType {
  if (data.type !== undefined) {
    return readEnum(data, "type", CORE_PAYMENT_TYPES);
  }
  if (data.provider === "mercadopago") {
    return "mercado-pago";
  }
  throw new TypeError("Firestore field \"type\" is required.");
}

/**
 * Reads a payment status, including the legacy mobile field name.
 * @param {DocumentData} data Firestore document data.
 * @return {CorePaymentStatus | undefined} Payment status, if present.
 */
function readOptionalPaymentStatus(
  data: DocumentData
): CorePaymentStatus | undefined {
  if (
    (data.status === undefined || data.status === null) &&
    (data.mercadoPagoStatus === undefined || data.mercadoPagoStatus === null)
  ) {
    return undefined;
  }
  return readEnum(data, "status", CORE_PAYMENT_STATUSES, "mercadoPagoStatus");
}

/**
 * Reads the recurring membership type from canonical or legacy data.
 * @param {DocumentData} data Firestore document data.
 * @return {CoreSubscriptionMembershipType | undefined} Membership type.
 */
function readOptionalSubscriptionType(
  data: DocumentData
): CoreSubscriptionMembershipType | undefined {
  if (
    (data.subscription_membership_type === undefined ||
      data.subscription_membership_type === null) &&
    (data.subscriptionMembershipType === undefined ||
      data.subscriptionMembershipType === null)
  ) {
    return undefined;
  }
  return readEnum(
    data,
    "subscription_membership_type",
    CORE_SUBSCRIPTION_MEMBERSHIP_TYPES,
    "subscriptionMembershipType"
  );
}

/**
 * Reads the recurring payment status from canonical or legacy data.
 * @param {DocumentData} data Firestore document data.
 * @return {CorePaymentSubscriptionStatus | undefined} Status, if present.
 */
function readOptionalSubscriptionStatus(
  data: DocumentData
): CorePaymentSubscriptionStatus | undefined {
  if (
    (data.subscription_status === undefined ||
      data.subscription_status === null) &&
    (data.subscriptionStatus === undefined ||
      data.subscriptionStatus === null)
  ) {
    return undefined;
  }
  return readEnum(
    data,
    "subscription_status",
    CORE_PAYMENT_SUBSCRIPTION_STATUSES,
    "subscriptionStatus"
  );
}

/**
 * Reads an optional bank issuer.
 * @param {DocumentData} data Firestore document data.
 * @return {CorePaymentIssuingEntity | undefined} Issuer, if present.
 */
function readOptionalIssuingEntity(
  data: DocumentData
): CorePaymentIssuingEntity | undefined {
  if (data.issuingEntity === undefined || data.issuingEntity === null) {
    return undefined;
  }
  return readEnum(data, "issuingEntity", CORE_PAYMENT_ISSUING_ENTITIES);
}

/**
 * Reads the optional source marker for subscription charges.
 * @param {DocumentData} data Firestore document data.
 * @return {"subscription" | undefined} Subscription source, if present.
 */
function readOptionalSource(data: DocumentData): "subscription" | undefined {
  if (data.source === undefined || data.source === null) {
    return undefined;
  }
  return readEnum(data, "source", ["subscription"]);
}

