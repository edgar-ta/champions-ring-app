import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreReceptionist} from "../models/core_receptionist.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de recepcionistas. */
export class CoreReceptionistRepository extends
  BaseRepository<CoreReceptionist> {
  /**
   * Crea un repositorio de recepcionistas.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección receptionists de Firestore. */
  protected get collectionPath(): string {
    return "receptionists";
  }

  /**
   * Crea un perfil de recepcionista a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreReceptionist} Perfil decodificado.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreReceptionist {
    return CoreReceptionist.fromFirestore(data, documentId);
  }
}
