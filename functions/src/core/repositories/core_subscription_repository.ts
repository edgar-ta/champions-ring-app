import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreSubscription} from "../models/core_subscription.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de suscripciones recurrentes. */
export class CoreSubscriptionRepository extends
  BaseRepository<CoreSubscription> {
  /**
   * Crea un repositorio de suscripciones.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección subscriptions de Firestore. */
  protected get collectionPath(): string {
    return "subscriptions";
  }

  /**
   * Crea una suscripción a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreSubscription} Suscripción decodificada.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreSubscription {
    return CoreSubscription.fromFirestore(data, documentId);
  }
}
