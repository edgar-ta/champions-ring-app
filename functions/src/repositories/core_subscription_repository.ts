import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreSubscription} from "../models/core_subscription.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for recurring subscriptions. */
export class CoreSubscriptionRepository extends
  BaseRepository<CoreSubscription> {
  /**
   * Creates a subscription repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore subscriptions collection. */
  protected get collectionPath(): string {
    return "subscriptions";
  }

  /**
   * Builds a subscription from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreSubscription} Decoded subscription.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreSubscription {
    return CoreSubscription.fromFirestore(data, documentId);
  }
}
