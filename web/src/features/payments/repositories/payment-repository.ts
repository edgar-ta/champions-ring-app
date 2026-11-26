// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import type { CorePaymentType } from "@/src/core/models/core_payment";

export interface ApprovedPayment {
  uid: string;
  type: CorePaymentType;
  amount: number;
  approvalDate: Date;
  payerName: string | null;
}

export interface PaymentRepository {
  /** Pagos con `approvalDate` desde la fecha indicada (sin dados de baja), del más reciente al más antiguo. */
  listApprovedSince(since: Date): Promise<ApprovedPayment[]>;
}
