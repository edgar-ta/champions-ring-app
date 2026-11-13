import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readDate,
  readOptionalDate,
  readString,
  readUid,
} from "./firestore_values.js";

/** Client profile stored in the clients collection. */
export class CoreClient extends FirestoreEntity {
  /** Creates a client profile. */
  constructor(
    readonly uid: string,
    readonly name: string,
    readonly lastName: string,
    readonly email: string,
    readonly creationDate: CoreDate,
    readonly sampleClassDate?: CoreDate,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Converts this client to its Firestore representation.
   * @return {DocumentData} Firestore document data.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      name: this.name,
      lastName: this.lastName,
      email: this.email,
      creationDate: this.creationDate.toFirebaseValue(),
      ...(this.sampleClassDate ?
        {sampleClassDate: this.sampleClassDate.toFirebaseValue()} :
        {}),
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Creates a client from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreClient} Decoded client.
   */
  static fromFirestore(data: DocumentData, documentId?: string): CoreClient {
    return new CoreClient(
      readUid(data, documentId),
      readString(data, "name"),
      readString(data, "lastName"),
      readString(data, "email"),
      readDate(data, "creationDate"),
      readOptionalDate(data, "sampleClassDate"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
