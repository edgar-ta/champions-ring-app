import type { DocumentReference, Timestamp } from "firebase/firestore";

/**
 * `members/{uid}` (Modelo de Datos en Firebase v20.0.0).
 * El nombre, los apellidos y el correo del miembro están en `clients/{uid}`.
 */
export interface Member {
  uid: string;
  birthDate: Timestamp;
  phone: string;
  photoUrl?: string | null;
  legalDataAreTheirs: boolean;
  inscriptionPaid: boolean;

  membershipPlanRef?: DocumentReference | null;
  latestRenewalRef?: DocumentReference | null;

  guardianName?: string | null;
  guardianPhone?: string | null;
  guardianRelationship?: string | null;
  curpUrl?: string | null;
  curpValidated?: boolean | null;

  ineBackUrl: string;
  ineBackValidated: boolean;
  ineFrontUrl: string;
  ineFrontValidated: boolean;

  waiverAgreementUrl?: string | null;
  waiverAgreementValidated?: boolean | null;

  // Extensión al modelo v20.0.0 (no existe en el documento): rechazo de un documento en recepción.
  // Si existe, el *Validated correspondiente está en false y el alumno debe volver a subir el archivo.
  ineFrontRejection?: DocumentRejection | null;
  ineBackRejection?: DocumentRejection | null;
  curpRejection?: DocumentRejection | null;
  waiverAgreementRejection?: DocumentRejection | null;

  creationDate: Timestamp;
  deletionDate?: Timestamp | null;
}

/** Motivo por el que la recepcionista rechazó un documento; la app se lo muestra al alumno. */
export interface DocumentRejection {
  comment: string;
  date: Timestamp;
  receptionistRef: DocumentReference;
}

/**
 * El miembro tiene algún documento sin validar. La CURP y la responsiva solo cuentan
 * si el miembro subió el archivo (la CURP solo la suben los menores de edad).
 */
export function hasPendingDocuments(member: Member): boolean {
  return member.ineFrontValidated !== true
    || member.ineBackValidated !== true
    || (!!member.curpUrl && member.curpValidated !== true)
    || (!!member.waiverAgreementUrl && member.waiverAgreementValidated !== true);
}
