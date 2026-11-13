import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readDate,
  readOptionalDate,
  readString,
  readUid,
} from "./firestore_values.js";

/** Receptionist profile stored in the receptionists collection. */
export class CoreReceptionist extends FirestoreEntity {
  /** Creates a receptionist profile. */
  constructor(
    readonly uid: string,
    readonly name: string,
    readonly lastName: string,
    readonly email: string,
    readonly creationDate: CoreDate,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Converts this receptionist to its Firestore representation.
   * @return {DocumentData} Firestore document data.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      name: this.name,
      lastName: this.lastName,
      email: this.email,
      creationDate: this.creationDate.toFirebaseValue(),
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Creates a receptionist from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreReceptionist} Decoded receptionist.
   */
  static fromFirestore(
    data: DocumentData,
    documentId?: string
  ): CoreReceptionist {
    return new CoreReceptionist(
      readUid(data, documentId),
      readString(data, "name"),
      readString(data, "lastName"),
      readString(data, "email"),
      readDate(data, "creationDate"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
