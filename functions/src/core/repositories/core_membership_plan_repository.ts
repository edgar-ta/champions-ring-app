import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreMembershipPlan} from "../models/core_membership_plan.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de planes de membresía. */
export class CoreMembershipPlanRepository extends
  BaseRepository<CoreMembershipPlan> {
  /**
   * Crea un repositorio de planes de membresía.
   * @param {Firestore} firestore Instancia de Firestore.
   */
  constructor(firestore: Firestore) {
    super(firestore);
  }

  /** Colección membership_plans de Firestore. */
  protected get collectionPath(): string {
    return "membership_plans";
  }

  /**
   * Crea un plan a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreMembershipPlan} Plan de membresía decodificado.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreMembershipPlan {
    return CoreMembershipPlan.fromFirestore(data, documentId);
  }

  /** Carga los planes que no están marcados como eliminados. */
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
