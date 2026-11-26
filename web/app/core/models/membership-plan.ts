import type { Timestamp } from "firebase/firestore";

/** "1d" = un día (visita), "1w" = una semana, "1m" = un mes. */
export type MembershipPlanDuration = "1d" | "1w" | "1m";

/** `membership_plans/{uid}` (Modelo de Datos en Firebase v20.0.0). */
export interface MembershipPlan {
  uid: string;
  cost: number;
  benefits: string;
  duration: MembershipPlanDuration;

  creationDate: Timestamp;
  deletionDate?: Timestamp | null;
}

export const DURATION_LABELS: Record<MembershipPlanDuration, string> = {
  "1d": "Día",
  "1w": "Semanal",
  "1m": "Mensual",
};
