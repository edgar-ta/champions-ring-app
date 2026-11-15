import type { MembershipPlanDuration } from "../models/membership-plan";

/**
 * Costo de inscripción en MXN. Se cobra una sola vez junto con el primer plan Semana o Mes.
 * Debe coincidir con REGISTRATION_FEE de functions/src/index.ts.
 */
export const INSCRIPTION_FEE = 120;

/** Días que cubre cada duración de plan (igual que MEMBERSHIPS en functions/src/index.ts). */
export const DURATION_DAYS: Record<MembershipPlanDuration, number> = {
  "1d": 1,
  "1w": 7,
  "1m": 30,
};
