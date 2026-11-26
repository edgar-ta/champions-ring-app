import type { Timestamp } from "firebase/firestore";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * `clients/{uid}` según `docs/dev-team/modelo-de-datos-en-firebase.md`
 * (versión 22.1.0).
 * Toda persona que acude al gimnasio: prospectos, usuarios ocasionales y miembros.
 * Un miembro además tiene `members/{uid}` con el mismo uid.
 */
export interface CoreClient {
  uid: string;
  name: string;
  lastName: string;
  email: string;

  sampleClassDate?: Timestamp;

  creationDate: Timestamp;
  deletionDate?: Timestamp;
}
