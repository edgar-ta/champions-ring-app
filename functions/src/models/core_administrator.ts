import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readDate,
  readOptionalDate,
  readString,
  readUid,
} from "./firestore_values.js";

/** Administrator profile stored in the administrators collection. */
export class CoreAdministrator extends FirestoreEntity {
  /** Creates an administrator profile. */
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
   * Converts this administrator to its Firestore representation.
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
   * Creates an administrator from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreAdministrator} Decoded administrator.
   */
  static fromFirestore(
    data: DocumentData,
    documentId?: string
  ): CoreAdministrator {
    return new CoreAdministrator(
      readUid(data, documentId),
      readString(data, "name"),
      readString(data, "lastName"),
      readString(data, "email"),
      readDate(data, "creationDate"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
