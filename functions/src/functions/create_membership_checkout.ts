import {Firestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import type {CoreMembershipPlan} from "../models/core_membership_plan.js";
import {
  CoreMembershipPlanRepository,
} from "../repositories/core_membership_plan_repository.js";

/**
 * Valida que exista un documento con la ID indicada en `membership_plans`.
 * Si la id no es válida, se lanza un `HttpsError`.
 * @param {unknown} membershipPlanUid ID del documento a validar.
 * @param {Firestore} firestore Instancia de Firestore para la consulta.
 * @return {Promise<CoreMembershipPlan>} Plan validado.
 */
export async function validateMembershipPlanUid(
  membershipPlanUid: unknown,
  firestore: Firestore
): Promise<CoreMembershipPlan> {
  if (
    typeof membershipPlanUid !== "string" ||
    membershipPlanUid.trim().length === 0 ||
    membershipPlanUid.includes("/")
  ) {
    throw new HttpsError(
      "invalid-argument",
      "El identificador del plan de membresía no es válido."
    );
  }

  const membershipPlan = await new CoreMembershipPlanRepository(firestore)
    .findById(membershipPlanUid);
  if (membershipPlan === undefined) {
    throw new HttpsError(
      "not-found",
      "El plan de membresía especificado no existe."
    );
  }
  return membershipPlan;
}
