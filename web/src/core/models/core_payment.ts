import type { DocumentReference, Timestamp } from "firebase/firestore";

export type CorePaymentType = "cash" | "direct-transfer" | "mercado-pago";
export type CorePaymentIssuingEntity = "bbva" | "santander" | "banco-azteca" | "elektra" | "other";
export type CorePaymentStatus =
  | "approved"
  | "rejected"
  | "processing"
  | "canceled"
  | "refunded";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * `payments/{uid}` según `docs/dev-team/modelo-de-datos-en-firebase.md`
 * (versión 22.1.0).
 */
export interface CorePayment {
  uid: string;
  type: CorePaymentType;

  amount: number;
  currency: "MXN" | "USD";
  approvalDate?: Timestamp;
  payerRef?: DocumentReference;

  // Solo mercado-pago
  checkoutUrl?: string;
  status?: CorePaymentStatus;
  preferenceId?: string;
  rejectionDetail?: string;

  // Solo direct-transfer
  referenceId?: string;
  issuingEntity?: CorePaymentIssuingEntity;
  issuingEntityName?: string;

  // cash y direct-transfer
  approverRef?: DocumentReference;

  creationDate: Timestamp;
  deletionDate?: Timestamp;
}

export const PAYMENT_TYPE_LABELS: Record<CorePaymentType, string> = {
  "cash": "Efectivo",
  "direct-transfer": "Transferencia",
  "mercado-pago": "Mercado Pago",
};
