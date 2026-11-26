import type { Timestamp } from "firebase/firestore";

/**
 * Duraciones del modelo en
 * `docs/dev-team/modelo-de-datos-en-firebase.md` (versión 22.1.0).
 */
export type CoreMembershipPlanDuration = "1d" | "1w" | "1m";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * `membership_plans/{uid}` según
 * `docs/dev-team/modelo-de-datos-en-firebase.md` (versión 22.1.0).
 */
export interface CoreMembershipPlan {
  uid: string;
  cost: number;
  benefits: string;
  duration: CoreMembershipPlanDuration;
  name: string;
  isRenewable: boolean;

  creationDate: Timestamp;
  deletionDate?: Timestamp;
}

export const DURATION_LABELS: Record<CoreMembershipPlanDuration, string> = {
  "1d": "Día",
  "1w": "Semanal",
  "1m": "Mensual",
};
