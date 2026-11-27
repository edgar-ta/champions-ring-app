import type {
  DocumentData,
  DocumentReference,
} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "../utils/firestore_entity.js";
import {
  readDate,
  readEnum,
  readNumber,
  readOptionalDate,
  readOptionalReference,
  readOptionalString,
  readUid,
} from "../utils/firestore_values.js";

/** Tipos de pago admitidos. */
export const CORE_PAYMENT_TYPES = [
  "cash",
  "direct-transfer",
  "mercado-pago",
] as const;
export type CorePaymentType = typeof CORE_PAYMENT_TYPES[number];

/** Monedas de pago admitidas. */
export const CORE_PAYMENT_CURRENCIES = ["MXN", "USD"] as const;
export type CorePaymentCurrency = typeof CORE_PAYMENT_CURRENCIES[number];

/** Estados de pago usados por la aplicación y las funciones de Mercado Pago. */
export const CORE_PAYMENT_STATUSES = [
  "approved",
  "rejected",
  "processing",
  "canceled",
  "refunded",
] as const;
export type CorePaymentStatus = typeof CORE_PAYMENT_STATUSES[number];

/** Entidades bancarias admitidas para pagos por transferencia. */
export const CORE_PAYMENT_ISSUING_ENTITIES = [
  "bbva",
  "santander",
  "banco-azteca",
  "elektra",
  "other",
] as const;
export type CorePaymentIssuingEntity =
  typeof CORE_PAYMENT_ISSUING_ENTITIES[number];

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * Documento de pago que cumple el esquema de la colección payments.
 */
export class CorePayment extends FirestoreEntity {
  /** Crea un pago. */
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
    readonly preferenceId?: string,
    readonly rejectionDetail?: string,
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
   * Convierte este pago al formato de Firestore.
   * @return {DocumentData} Datos del documento de Firestore.
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
      ...(this.preferenceId !== undefined ?
        {preferenceId: this.preferenceId} :
        {}),
      ...(this.rejectionDetail !== undefined ?
        {rejectionDetail: this.rejectionDetail} :
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
   * Crea un pago a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} [documentId] ID alternativo del documento.
   * @return {CorePayment} Pago decodificado.
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
      readOptionalString(data, "preferenceId"),
      readOptionalString(data, "rejectionDetail"),
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
 * Lee el tipo de pago e infiere el tipo heredado de Mercado Pago si hace falta.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @return {CorePaymentType} Tipo de pago.
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
 * Lee el estado de pago, incluido el nombre de campo heredado de la app móvil.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @return {CorePaymentStatus | undefined} Estado de pago, si está presente.
 */
function readOptionalPaymentStatus(
  data: DocumentData
): CorePaymentStatus | undefined {
  const status = data.status ?? data.mercadoPagoStatus;
  if (status === undefined || status === null) {
    return undefined;
  }
  if (status === "pending" || status === "authorized" ||
    status === "in_process") {
    return "processing";
  }
  if (status === "checkout_creation_failed") {
    return undefined;
  }
  if (status === "cancelled") {
    return "canceled";
  }
  return readEnum(data, "status", CORE_PAYMENT_STATUSES, "mercadoPagoStatus");
}

/**
 * Lee una entidad bancaria opcional.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @return {CorePaymentIssuingEntity | undefined} Entidad, si está presente.
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
 * Lee el indicador opcional de origen para los cargos de suscripción.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @return {"subscription" | undefined} Origen de la suscripción, si existe.
 */
function readOptionalSource(data: DocumentData): "subscription" | undefined {
  if (data.source === undefined || data.source === null) {
    return undefined;
  }
  return readEnum(data, "source", ["subscription"]);
}

