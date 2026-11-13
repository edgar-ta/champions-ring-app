import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreMember} from "../models/core_member.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for members. */
export class CoreMemberRepository extends BaseRepository<CoreMember> {
  /**
   * Creates a member repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore members collection. */
  protected get collectionPath(): string {
    return "members";
  }

  /**
   * Builds a member from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreMember} Decoded member.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreMember {
    return CoreMember.fromFirestore(data, documentId);
  }

  /**
   * Saves a member only when its matching client document exists.
   * @param {CoreMember} member Member to save.
   * @return {Promise<boolean>} True when the member was created.
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
      transaction.set(memberDocument, member.toFirestore());
      return !memberSnapshot.exists;
    });
  }
}
