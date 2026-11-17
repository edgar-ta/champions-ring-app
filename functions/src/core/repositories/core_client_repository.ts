import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreClient} from "../models/core_client.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de clientes. */
export class CoreClientRepository extends BaseRepository<CoreClient> {
  /**
   * Crea un repositorio de clientes.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección clients de Firestore. */
  protected get collectionPath(): string {
    return "clients";
  }

  /**
   * Crea un cliente a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreClient} Cliente decodificado.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreClient {
    return CoreClient.fromFirestore(data, documentId);
  }
}
