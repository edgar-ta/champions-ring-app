import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreAdministrator} from "../models/core_administrator.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for administrators. */
export class CoreAdministratorRepository extends
  BaseRepository<CoreAdministrator> {
  /**
   * Creates an administrator repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore administrators collection. */
  protected get collectionPath(): string {
    return "administrators";
  }

  /**
   * Builds an administrator from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreAdministrator} Decoded administrator.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreAdministrator {
    return CoreAdministrator.fromFirestore(data, documentId);
  }
}
