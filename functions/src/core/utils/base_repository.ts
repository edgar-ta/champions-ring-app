import type {
  CollectionReference,
  DocumentData,
  Firestore,
} from "firebase-admin/firestore";
import {FirestoreEntity} from "./firestore_entity.js";

/**
 * Proporciona operaciones comunes de Firestore para los repositorios
 * de entidades.
 */
export abstract class BaseRepository<Entity extends FirestoreEntity> {
  /**
   * Crea un repositorio asociado a la instancia de Firestore indicada.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  protected constructor(protected readonly firestore: Firestore) {}

  /** Ruta de la colección administrada por este repositorio. */
  protected abstract get collectionPath(): string;

  /** Crea una entidad a partir de un documento de Firestore. */
  protected abstract fromFirestore(
    data: DocumentData,
    documentId: string
  ): Entity;

  /** Referencia a la colección administrada por este repositorio. */
  get collection(): CollectionReference<DocumentData> {
    return this.firestore.collection(this.collectionPath);
  }

  /** Genera un identificador de documento sin usar en la colección. */
  get nextUid(): string {
    return this.collection.doc().id;
  }

  /**
   * Inserta o reemplaza una entidad dentro de una transacción.
   * @param {Entity} entity Entidad que se guardará.
   * @return {Promise<boolean>} Indica si se creó el documento.
   * Conserva los campos uid y creationDate del documento existente
   * al actualizar.
   */
  async upsert(entity: Entity): Promise<boolean> {
    const document = this.collection.doc(entity.uid);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(document);
      transaction.set(
        document,
        this.dataForUpsert(entity, snapshot.data())
      );
      return !snapshot.exists;
    });
  }

  /**
   * Builds document data while keeping its original identity and creation time.
   * @param {Entity} entity Entity to serialize.
   * @param {DocumentData} existingData Existing document data, if present.
   * @return {DocumentData} Data to write.
   */
  protected dataForUpsert(
    entity: Entity,
    existingData?: DocumentData
  ): DocumentData {
    const data = {...entity.toFirestore()};
    if (existingData !== undefined) {
      for (const field of ["uid", "creationDate"] as const) {
        if (Object.prototype.hasOwnProperty.call(existingData, field)) {
          data[field] = existingData[field];
        }
      }
    }
    return data;
  }

  /**
   * Carga una entidad o lanza un error si el documento no existe.
   * @param {string} uid Identificador del documento.
   * @return {Promise<Entity>} Entidad cargada.
   */
  async getById(uid: string): Promise<Entity> {
    const entity = await this.findById(uid);
    if (entity === undefined) {
      throw new Error(
        `${this.constructor.name} document "${uid}" was not found.`
      );
    }
    return entity;
  }

  /**
   * Carga una entidad o devuelve undefined si el documento no existe.
   * @param {string} uid Identificador del documento.
   * @return {Promise<Entity | undefined>} Entidad cargada, si existe.
   */
  async findById(uid: string): Promise<Entity | undefined> {
    const snapshot = await this.collection.doc(uid).get();
    const data = snapshot.data();
    if (!snapshot.exists || data === undefined) {
      return undefined;
    }
    return this.fromFirestore(data, snapshot.id);
  }

  /**
   * Comprueba si existe un documento en la colección.
   * @param {string} uid Identificador del documento.
   * @return {Promise<boolean>} Indica si existe el documento.
   */
  async isDocumentPresent(uid: string): Promise<boolean> {
    const snapshot = await this.collection.doc(uid).get();
    return snapshot.exists;
  }
}
