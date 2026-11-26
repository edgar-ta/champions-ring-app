import type {
  CoreMembershipPlan,
  CoreMembershipPlanDuration,
} from "@/src/core/models/core_membership_plan";

export interface MembershipPlanInput {
  cost: number;
  benefits: string;
  duration: CoreMembershipPlanDuration;
}

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * Plan con el id de su documento (al que apuntan las referencias de members y
 * renewals).
 */
export interface PlanRecord {
  id: string;
  plan: CoreMembershipPlan;
  active: boolean;
}

export interface MembershipPlanRepository {
  /** Todos los planes, activos e inactivos, de menor a mayor duración. */
  listPlans(): Promise<PlanRecord[]>;
  createPlan(input: MembershipPlanInput): Promise<string>;
  updatePlan(id: string, input: MembershipPlanInput): Promise<void>;
  /** Baja lógica: guarda `deletionDate`. El documento no se borra porque members y renewals lo referencian. */
  deactivatePlan(id: string): Promise<void>;
  reactivatePlan(id: string): Promise<void>;
}
