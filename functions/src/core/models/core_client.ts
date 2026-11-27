import type {DocumentData} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "../utils/firestore_entity.js";
import {
  readDate,
  readOptionalDate,
  readString,
  readUid,
} from "../utils/firestore_values.js";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * Perfil de cliente almacenado en la colección clients.
 */
export class CoreClient extends FirestoreEntity {
  /** Crea un perfil de cliente. */
  constructor(
    readonly uid: string,
    readonly name: string,
    readonly lastName: string,
    readonly email: string,
    readonly creationDate: CoreDate,
    readonly sampleClassDate?: CoreDate,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Convierte este cliente al formato de Firestore.
   * @return {DocumentData} Datos del documento de Firestore.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      name: this.name,
      lastName: this.lastName,
      email: this.email,
      creationDate: this.creationDate.toFirebaseValue(),
      ...(this.sampleClassDate ?
        {sampleClassDate: this.sampleClassDate.toFirebaseValue()} :
        {}),
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Crea un cliente a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} [documentId] ID alternativo del documento.
   * @return {CoreClient} Cliente decodificado.
   */
  static fromFirestore(data: DocumentData, documentId?: string): CoreClient {
    return new CoreClient(
      readUid(data, documentId),
      readString(data, "name"),
      readString(data, "lastName"),
      readString(data, "email"),
      readDate(data, "creationDate"),
      readOptionalDate(data, "sampleClassDate"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
