import type { DocumentReference, Timestamp } from "firebase/firestore";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * `members/{uid}/renewals/{uid}` según
 * `docs/dev-team/modelo-de-datos-en-firebase.md` (versión 22.1.0).
 */
export interface CoreRenewal {
  uid: string;
  startDate: Timestamp;
  endDate: Timestamp;
  membershipPlanRef: DocumentReference;
  paymentRef: DocumentReference;
  amount: number;

  creationDate: Timestamp;
  deletionDate?: Timestamp;
}
