// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import type { CoreMember } from "@/src/core/models/core_member";

/** Estado de la membresía según la fecha de fin de la renovación más reciente. */
export type MembershipStatus = "active" | "expiring" | "expired" | "none";

/** Días antes del vencimiento en los que una membresía se considera "por vencer". */
export const EXPIRING_WINDOW_DAYS = 3;

export const STATUS_LABELS: Record<MembershipStatus, string> = {
  active: "Activo",
  expiring: "Por vencer",
  expired: "Vencido",
  none: "Sin membresía",
};

/** Datos de un alumno para el panel: une members/{uid}, clients/{uid}, su última renovación y su plan. */
export interface MemberSummary {
  uid: string;
  fullName: string;
  email: string;
  phone: string;
  photoUrl: string | null;
  age: number | null;
  guardianName: string | null;
  inscriptionPaid: boolean;
  documentsValidated: boolean;
  /** Id en `membership_plans` del plan de su renovación más reciente (o de su membershipPlanRef). */
  planId: string | null;
  planLabel: string | null;
  membershipEnd: Date | null;
  status: MembershipStatus;
  creationDate: Date | null;
  /** Documento completo de members/{uid} (URLs y validación de documentos, datos del tutor). */
  record: CoreMember;
}

export function membershipStatus(end: Date | null, now = new Date()): MembershipStatus {
  if (!end) return "none";
  if (end <= now) return "expired";
  return end.getTime() - now.getTime() <= EXPIRING_WINDOW_DAYS * 24 * 60 * 60 * 1000 ? "expiring" : "active";
}
