import type { DocumentReference, Timestamp } from "firebase/firestore";

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * `members/{uid}` según `docs/dev-team/modelo-de-datos-en-firebase.md`
 * (versión 22.1.0).
 * El nombre, los apellidos y el correo del miembro están en `clients/{uid}`.
 */
export interface CoreMember {
  uid: string;
  birthDate: Timestamp;
  phone: string;
  photoUrl?: string;
  legalDataAreTheirs: boolean;
  inscriptionPaid: boolean;

  membershipPlanRef?: DocumentReference;
  latestRenewalRef?: DocumentReference;

  guardianName?: string;
  guardianPhone?: string;
  guardianRelationship?: string;
  curpUrl?: string;
  curpValidated?: boolean;

  ineBackUrl: string;
  ineBackValidated: boolean;
  ineFrontUrl: string;
  ineFrontValidated: boolean;

  waiverAgreementUrl?: string;
  waiverAgreementValidated?: boolean;

  creationDate: Timestamp;
  deletionDate?: Timestamp;
}

/**
 * El miembro tiene algún documento sin validar. La CURP y la responsiva solo cuentan
 * si el miembro subió el archivo (la CURP solo la suben los menores de edad).
 */
export function hasPendingDocuments(member: CoreMember): boolean {
  return member.ineFrontValidated !== true
    || member.ineBackValidated !== true
    || (!!member.curpUrl && member.curpValidated !== true)
    || (!!member.waiverAgreementUrl && member.waiverAgreementValidated !== true);
}
