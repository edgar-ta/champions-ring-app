import type { Client } from "@/app/core/models/client";
import type { EmailLookup, MemberRecord, MembershipResult, PaymentDetails, PersonalData, PlanCatalog, PlanOption, WaiverSignature } from "../models/registration";

export interface RegistrationRepository {
  /** Busca el correo en `clients` y dice si ya es alumno (`members`). */
  lookupEmail(email: string): Promise<EmailLookup>;

  /** Planes vigentes de `membership_plans` (de menor a mayor duración) y los documentos que no son válidos. */
  listPlans(): Promise<PlanCatalog>;

  /** Prospecto: crea `clients/{uid}` con la fecha de hoy como `sampleClassDate`. */
  registerSampleClass(personal: PersonalData): Promise<Client>;

  /** Usuario ocasional: reutiliza o crea su `clients/{uid}` y registra el pago de la visita. */
  registerVisit(input: { personal: PersonalData; existing: Client | null; plan: PlanOption; payment: PaymentDetails; receptionistUid: string }): Promise<void>;

  /**
   * Alumno con plan: crea su cuenta de la app, sube sus documentos y la responsiva firmada,
   * crea `clients` y `members`, registra el pago y, si quedó aprobado, su renovación.
   */
  registerMember(input: {
    personal: PersonalData;
    existing: Client | null;
    record: MemberRecord;
    waiver: WaiverSignature;
    plan: PlanOption;
    payment: PaymentDetails;
    receptionistUid: string;
  }): Promise<MembershipResult>;
}
