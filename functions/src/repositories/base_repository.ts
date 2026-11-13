import type {
  CollectionReference,
  DocumentData,
  Firestore,
} from "firebase-admin/firestore";
import {FirestoreEntity} from "../models/firestore_entity.js";

/** Provides common Firestore operations for entity repositories. */
export abstract class BaseRepository<Entity extends FirestoreEntity> {
  /**
   * Creates a repository backed by the given Firestore instance.
   * @param {Firestore} firestore Firestore instance.
   */
  protected constructor(protected readonly firestore: Firestore) {}

  /** Collection path managed by this repository. */
  protected abstract get collectionPath(): string;

  /** Builds an entity from a Firestore document. */
  protected abstract fromFirestore(
    data: DocumentData,
    documentId: string
  ): Entity;

  /** Collection reference managed by this repository. */
  protected get collection(): CollectionReference<DocumentData> {
    return this.firestore.collection(this.collectionPath);
  }

  /** Generates an unused document identifier in the collection. */
  get nextUid(): string {
    return this.collection.doc().id;
  }

  /**
   * Inserts or replaces an entity transactionally.
   * @param {Entity} entity Entity to write.
   * @return {Promise<boolean>} True when the document was created.
   */
  async upsert(entity: Entity): Promise<boolean> {
    const document = this.collection.doc(entity.uid);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(document);
      transaction.set(document, entity.toFirestore());
      return !snapshot.exists;
    });
  }

  /**
   * Loads an entity or throws when its document does not exist.
   * @param {string} uid Document identifier.
   * @return {Promise<Entity>} Loaded entity.
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
   * Loads an entity, returning undefined when its document does not exist.
   * @param {string} uid Document identifier.
   * @return {Promise<Entity | undefined>} Loaded entity, if found.
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
   * Checks whether a document exists in the collection.
   * @param {string} uid Document identifier.
   * @return {Promise<boolean>} Whether the document exists.
   */
  async isDocumentPresent(uid: string): Promise<boolean> {
    const snapshot = await this.collection.doc(uid).get();
    return snapshot.exists;
  }
}
