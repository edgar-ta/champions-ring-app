import type { PaymentType } from "@/app/core/models/payment";

/** "visit": usuario ocasional que pagó al menos una visita. "sample": prospecto que solo tomó su clase muestra. */
export type VisitorKind = "visit" | "sample";

export const VISITOR_LABELS: Record<VisitorKind, string> = {
  visit: "Visita",
  sample: "Clase muestra",
};

export interface Visit {
  paymentUid: string;
  /** Cuándo se registró la visita (creationDate del pago). */
  date: Date;
  amount: number;
  type: PaymentType;
  /** Pago de Mercado Pago que todavía no se confirma (sin approvalDate). */
  pending: boolean;
}

/** Persona en `clients` que no es alumno (no tiene `members/{uid}`): visitante o prospecto. */
export interface VisitorSummary {
  uid: string;
  fullName: string;
  email: string;
  kind: VisitorKind;
  sampleClassDate: Date | null;
  /** Del más reciente al más antiguo. */
  visits: Visit[];
  /** Última visita, o la clase muestra si no ha pagado ninguna. */
  lastDate: Date | null;
  creationDate: Date | null;
}
