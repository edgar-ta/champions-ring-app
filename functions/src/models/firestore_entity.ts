import type {DocumentData} from "firebase-admin/firestore";

/** Base contract for an entity stored as a Firestore document. */
export abstract class FirestoreEntity {
  /** Document identifier. */
  abstract readonly uid: string;

  /** Converts the entity into Firestore-compatible data. */
  abstract toFirestore(): DocumentData;
}
