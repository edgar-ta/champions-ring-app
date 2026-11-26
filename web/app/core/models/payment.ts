import type { DocumentReference, Timestamp } from "firebase/firestore";

export type PaymentType = "cash" | "direct-transfer" | "mercado-pago";
export type IssuingEntity = "bbva" | "santander" | "banco-azteca" | "elektra" | "other";

/** `payments/{uid}` (Modelo de Datos en Firebase v20.0.0). */
export interface Payment {
  uid: string;
  type: PaymentType;

  amount: number;
  currency: "MXN" | "USD";
  approvalDate?: Timestamp | null;
  payerRef?: DocumentReference | null;

  // Solo mercado-pago
  checkoutUrl?: string | null;
  status?: ("approved" | "rejected") | null;
  mercadoPagoPaymentId?: string | null;
  preferenceId?: string | null;

  // Solo direct-transfer
  referenceId?: string | null;
  issuingEntity?: IssuingEntity | null;
  issuingEntityName?: string | null;

  // cash y direct-transfer
  approverRef?: DocumentReference | null;

  creationDate: Timestamp;
  deletionDate?: Timestamp | null;
}

export const PAYMENT_TYPE_LABELS: Record<PaymentType, string> = {
  "cash": "Efectivo",
  "direct-transfer": "Transferencia",
  "mercado-pago": "Mercado Pago",
};
