import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreMembershipPlan} from "../models/core_membership_plan.js";
import {BaseRepository} from "./base_repository.js";

/** Repository for membership plans. */
export class CoreMembershipPlanRepository extends
  BaseRepository<CoreMembershipPlan> {
  /**
   * Creates a membership plan repository.
   * @param {Firestore} firestore Firestore instance.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Firestore membership_plans collection. */
  protected get collectionPath(): string {
    return "membership_plans";
  }

  /**
   * Builds a plan from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} documentId Firestore document id.
   * @return {CoreMembershipPlan} Decoded membership plan.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreMembershipPlan {
    return CoreMembershipPlan.fromFirestore(data, documentId);
  }

  /** Loads plans that are not marked as deleted. */
  async getActiveMembershipPlans(): Promise<CoreMembershipPlan[]> {
    const snapshot = await this.collection.get();
    return snapshot.docs
      .filter((document) => {
        const deletionDate = document.data().deletionDate;
        return deletionDate === undefined || deletionDate === null;
      })
      .map((document) => this.fromFirestore(document.data(), document.id));
  }
}
