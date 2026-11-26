import type { Timestamp } from "firebase/firestore";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * `receptionists/{uid}` según
 * `docs/dev-team/modelo-de-datos-en-firebase.md` (versión 22.1.0).
 */
export interface CoreReceptionist {
  uid: string;
  name: string;
  lastName: string;
  email: string;

  creationDate: Timestamp;
  deletionDate?: Timestamp;
}
