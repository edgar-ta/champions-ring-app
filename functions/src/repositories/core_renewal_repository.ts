import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreRenewal} from "../models/core_renewal.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for renewals in a member's renewals subcollection. */
export class CoreRenewalRepository extends BaseRepository<CoreRenewal> {
  /**
   * Creates a renewal repository for the specified member.
   * @param {Firestore} firestore Firestore instance.
   * @param {string} memberUid Parent member document id.
   */
  constructor(
    firestore: Firestore,
    private readonly memberUid: string
  ) {
    super(firestore);
    if (memberUid.trim().length === 0 || memberUid.includes("/")) {
      throw new TypeError("A valid member uid is required.");
    }
  }

  /** Firestore renewals subcollection path. */
  protected get collectionPath(): string {
    return `members/${this.memberUid}/renewals`;
  }

  /**
   * Builds a renewal from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreRenewal} Decoded renewal.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreRenewal {
    return CoreRenewal.fromFirestore(data, documentId);
  }

  /**
   * Validates renewal references and saves the document transactionally.
   * @param {CoreRenewal} renewal Renewal to save.
   * @return {Promise<boolean>} True when the renewal was created.
   */
  override async upsert(renewal: CoreRenewal): Promise<boolean> {
    if (renewal.paymentRef.parent.path !== "payments") {
      throw new TypeError(
        "renewal.paymentRef must reference a payments document."
      );
    }
    if (renewal.membershipPlanRef.parent.path !== "membership_plans") {
      throw new TypeError(
        "renewal.membershipPlanRef must reference a membership_plans " +
          "document."
      );
    }

    const memberDocument = this.firestore.collection("members")
      .doc(this.memberUid);
    const renewalDocument = this.collection.doc(renewal.uid);

    return this.firestore.runTransaction(async (transaction) => {
      const memberSnapshot = await transaction.get(memberDocument);
      if (!memberSnapshot.exists) {
        throw new Error(`Member "${this.memberUid}" was not found.`);
      }

      const paymentSnapshot = await transaction.get(renewal.paymentRef);
      if (!paymentSnapshot.exists) {
        throw new Error(
          `Payment "${renewal.paymentRef.path}" was not found.`
        );
      }

      const membershipPlanSnapshot =
        await transaction.get(renewal.membershipPlanRef);
      if (!membershipPlanSnapshot.exists) {
        throw new Error(
          `Membership plan "${renewal.membershipPlanRef.path}" was not found.`
        );
      }

      const renewalSnapshot = await transaction.get(renewalDocument);
      transaction.set(renewalDocument, renewal.toFirestore());
      return !renewalSnapshot.exists;
    });
  }
}
