import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreReceptionist} from "../models/core_receptionist.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for receptionists. */
export class CoreReceptionistRepository extends
  BaseRepository<CoreReceptionist> {
  /**
   * Creates a receptionist repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore receptionists collection. */
  protected get collectionPath(): string {
    return "receptionists";
  }

  /**
   * Builds a receptionist from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreReceptionist} Decoded receptionist.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreReceptionist {
    return CoreReceptionist.fromFirestore(data, documentId);
  }
}
