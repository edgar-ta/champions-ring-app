import type { Client } from "@/app/core/models/client";
import type { Member } from "@/app/core/models/member";

/** Campos booleanos de `members` que valida el recepcionista. */
export type MemberDocumentField = "ineFrontValidated" | "ineBackValidated" | "curpValidated" | "waiverAgreementValidated";

/** Campo de `members` donde se guarda el rechazo de cada documento (extensión al modelo v20.0.0). */
export const REJECTION_FIELDS = {
  ineFrontValidated: "ineFrontRejection",
  ineBackValidated: "ineBackRejection",
  curpValidated: "curpRejection",
  waiverAgreementValidated: "waiverAgreementRejection",
} as const satisfies Record<MemberDocumentField, keyof Member>;

/** Un miembro con al menos un documento sin validar, junto con su `clients/{uid}`. */
export interface PendingMember {
  member: Member;
  client: Client | null;
}

export interface MemberDocumentsRepository {
  /**
   * Escucha en tiempo real a los miembros activos con algún documento sin validar,
   * del documento `members` más antiguo al más reciente. Devuelve la función para dejar de escuchar.
   */
  watchPendingMembers(onChange: (members: PendingMember[]) => void, onError: (error: unknown) => void): () => void;

  /** Marca como válido un documento de `members/{uid}` y borra su rechazo, si lo tenía. */
  validate(memberUid: string, field: MemberDocumentField): Promise<void>;

  /** Rechaza un documento: su *Validated queda en false y se guarda el comentario para el alumno. */
  reject(memberUid: string, field: MemberDocumentField, comment: string, receptionistUid: string): Promise<void>;
}
