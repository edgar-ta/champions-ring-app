import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreMember} from "../models/core_member.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de miembros. */
export class CoreMemberRepository extends BaseRepository<CoreMember> {
  /**
   * Crea un repositorio de miembros.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección members de Firestore. */
  protected get collectionPath(): string {
    return "members";
  }

  /**
   * Crea un miembro a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreMember} Miembro decodificado.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreMember {
    return CoreMember.fromFirestore(data, documentId);
  }

  /**
   * Guarda un miembro solo si existe el documento del cliente asociado.
   * @param {CoreMember} member Miembro que se guardará.
   * @return {Promise<boolean>} Indica si se creó el miembro.
   */
  override async upsert(member: CoreMember): Promise<boolean> {
    const memberDocument = this.collection.doc(member.uid);
    const clientDocument = this.firestore.collection("clients").doc(member.uid);

    return this.firestore.runTransaction(async (transaction) => {
      const clientSnapshot = await transaction.get(clientDocument);
      if (!clientSnapshot.exists) {
        throw new Error(
          `Cannot create member "${member.uid}" without an existing client.`
        );
      }

      const memberSnapshot = await transaction.get(memberDocument);
      transaction.set(
        memberDocument,
        this.dataForUpsert(member, memberSnapshot.data())
      );
      return !memberSnapshot.exists;
    });
  }
}
