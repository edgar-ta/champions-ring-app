import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreAdministrator} from "../models/core_administrator.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de administradores. */
export class CoreAdministratorRepository extends
  BaseRepository<CoreAdministrator> {
  /**
   * Crea un repositorio de administradores.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección administrators de Firestore. */
  protected get collectionPath(): string {
    return "administrators";
  }

  /**
   * Crea un administrador a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreAdministrator} Administrador decodificado.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreAdministrator {
    return CoreAdministrator.fromFirestore(data, documentId);
  }
}
