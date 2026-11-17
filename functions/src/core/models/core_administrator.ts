import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "../utils/firestore_entity.js";
import {
  readDate,
  readOptionalDate,
  readString,
  readUid,
} from "../utils/firestore_values.js";

/** Perfil de administrador almacenado en la colección administrators. */
export class CoreAdministrator extends FirestoreEntity {
  /** Crea un perfil de administrador. */
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
   * Convierte este administrador al formato de Firestore.
   * @return {DocumentData} Datos del documento de Firestore.
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
   * Crea un administrador a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} [documentId] ID alternativo del documento.
   * @return {CoreAdministrator} Administrador decodificado.
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
