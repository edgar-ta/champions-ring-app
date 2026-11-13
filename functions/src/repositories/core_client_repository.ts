import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreClient} from "../models/core_client.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for clients. */
export class CoreClientRepository extends BaseRepository<CoreClient> {
  /**
   * Creates a client repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore clients collection. */
  protected get collectionPath(): string {
    return "clients";
  }

  /**
   * Builds a client from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreClient} Decoded client.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreClient {
    return CoreClient.fromFirestore(data, documentId);
  }
}
