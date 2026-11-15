import type { MembershipPlan, MembershipPlanDuration } from "@/app/core/models/membership-plan";

export interface MembershipPlanInput {
  cost: number;
  benefits: string;
  duration: MembershipPlanDuration;
}

/** Plan con el id de su documento (al que apuntan las referencias de members y renewals). */
export interface PlanRecord {
  id: string;
  plan: MembershipPlan;
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
