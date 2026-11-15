import type { PaymentType } from "@/app/core/models/payment";

export interface ApprovedPayment {
  uid: string;
  type: PaymentType;
  amount: number;
  approvalDate: Date;
  payerName: string | null;
}

export interface PaymentRepository {
  /** Pagos con `approvalDate` desde la fecha indicada (sin dados de baja), del más reciente al más antiguo. */
  listApprovedSince(since: Date): Promise<ApprovedPayment[]>;
}
