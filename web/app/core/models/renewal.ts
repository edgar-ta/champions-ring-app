import type { DocumentReference, Timestamp } from "firebase/firestore";

/** `members/{uid}/renewals/{id}` (Modelo de Datos en Firebase v20.0.0). */
export interface Renewal {
  uid: string;
  startDate: Timestamp;
  endDate: Timestamp;
  membershipPlanRef?: DocumentReference | null;
  paymentRef: DocumentReference;
  amount: number;

  creationDate: Timestamp;
  deletionDate?: Timestamp | null;
}
