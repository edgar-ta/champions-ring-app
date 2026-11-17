import type {DocumentData, Firestore} from "firebase-admin/firestore";
import {CoreRenewal} from "../models/core_renewal.js";
import {BaseRepository} from "../utils/base_repository.js";

/** Repositorio de renovaciones en la subcolección renewals de un miembro. */
export class CoreRenewalRepository extends BaseRepository<CoreRenewal> {
  /**
   * Crea un repositorio de renovaciones para el miembro indicado.
   * @param {Firestore} firestore Instancia de Firestore.
   * @param {string} memberUid ID del documento del miembro.
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

  /** Ruta de la subcolección renewals en Firestore. */
  protected get collectionPath(): string {
    return `members/${this.memberUid}/renewals`;
  }

  /**
   * Crea una renovación a partir de un documento de Firestore.
   * @param {DocumentData} data Datos del documento de Firestore.
   * @param {string} documentId ID del documento de Firestore.
   * @return {CoreRenewal} Renovación decodificada.
   */
  protected fromFirestore(
    data: DocumentData,
    documentId: string
  ): CoreRenewal {
    return CoreRenewal.fromFirestore(data, documentId);
  }

  /**
   * Valida las referencias de la renovación y la guarda en una transacción.
   * @param {CoreRenewal} renewal Renovación que se guardará.
   * @return {Promise<boolean>} Indica si se creó la renovación.
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
