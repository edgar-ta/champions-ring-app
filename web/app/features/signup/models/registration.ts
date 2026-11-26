import type { Client } from "@/app/core/models/client";
import type { MembershipPlan } from "@/app/core/models/membership-plan";
import type { IssuingEntity } from "@/app/core/models/payment";

/**
 * Tipo de cliente que se decide en el paso de membresía:
 * - sample: prospecto que toma su clase muestra (gratis, solo clients).
 * - visit: usuario ocasional que paga la visita (clients + payments).
 * - membership: alumno con plan Semana o Mes (cuenta, clients, members, payments y renewals).
 */
export type RegistrationKind = "sample" | "visit" | "membership";

export interface PersonalData {
  name: string;
  lastName: string;
  email: string;
}

/** Resultado de buscar el correo en el paso de datos personales. */
export interface EmailLookup {
  /** Cliente activo con ese correo, si existe. */
  client: Client | null;
  /** Ya tiene un documento activo en `members`. */
  isMember: boolean;
}

/** Datos del expediente que solo se piden a los alumnos (Semana o Mes). */
export interface MemberRecord {
  birthDate: Date;
  phone: string;
  photo: File;
  ineFront: File;
  ineBack: File;
  /** Solo menores de edad. */
  curp: File | null;
  guardianName: string | null;
  guardianPhone: string | null;
  guardianRelationship: string | null;
}

export interface WaiverSignature {
  /** Firma en PNG (data URL) dibujada en pantalla. */
  signatureDataUrl: string;
  signedAt: Date;
}

export type PaymentDetails =
  | { type: "cash" }
  | { type: "direct-transfer"; referenceId: string; issuingEntity: IssuingEntity; issuingEntityName?: string }
  | { type: "mercado-pago"; mercadoPagoPaymentId: string };

export interface PlanOption {
  /** Id del documento en `membership_plans` (al que apuntan las referencias). */
  id: string;
  plan: MembershipPlan;
}

/** Planes válidos y documentos de `membership_plans` que no cumplen el modelo v20.0.0 (con el motivo). */
export interface PlanCatalog {
  plans: PlanOption[];
  ignored: { id: string; reason: string }[];
}

/** Resultado de registrar a un alumno con plan. */
export interface MembershipResult {
  uid: string;
  /** El pago quedó aprobado y se creó la renovación (efectivo o transferencia). */
  activated: boolean;
  /** Avisos de pasos secundarios que fallaron sin deshacer el registro. */
  warnings: string[];
}

export function isMinor(birthDate: Date, today = new Date()): boolean {
  let age = today.getFullYear() - birthDate.getFullYear();
  if (today.getMonth() < birthDate.getMonth() || (today.getMonth() === birthDate.getMonth() && today.getDate() < birthDate.getDate())) age--;
  return age < 18;
}
