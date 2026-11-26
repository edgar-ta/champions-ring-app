// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import type { CoreMembershipPlanDuration } from "../models/core_membership_plan";

/**
 * Costo de inscripción en MXN. Se cobra una sola vez junto con el primer plan Semana o Mes.
 * Debe coincidir con REGISTRATION_FEE de functions/src/index.ts.
 */
export const INSCRIPTION_FEE = 120;

/** Días que cubre cada duración de plan (igual que MEMBERSHIPS en functions/src/index.ts). */
export const DURATION_DAYS: Record<CoreMembershipPlanDuration, number> = {
  "1d": 1,
  "1w": 7,
  "1m": 30,
};
