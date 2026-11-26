import type { DocumentReference, Timestamp } from "firebase/firestore";

import type { CoreClient } from "@/src/core/models/core_client";
import type { CoreMember } from "@/src/core/models/core_member";

/** Campos booleanos de `members` que valida el recepcionista. */
export type MemberDocumentField = "ineFrontValidated" | "ineBackValidated" | "curpValidated" | "waiverAgreementValidated";

/** Metadatos de rechazo que consume el flujo de validación documental web. */
export interface DocumentRejection {
  comment: string;
  date: Timestamp;
  receptionistRef: DocumentReference;
}

/**
 * @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
 * Campos adicionales usados por validación documental fuera del modelo
 * principal de `members`.
 */
export interface MemberWithDocumentRejections extends CoreMember {
  ineFrontRejection?: DocumentRejection | null;
  ineBackRejection?: DocumentRejection | null;
  curpRejection?: DocumentRejection | null;
  waiverAgreementRejection?: DocumentRejection | null;
}

/** Campo donde el flujo web guarda el rechazo de cada documento. */
export const REJECTION_FIELDS = {
  ineFrontValidated: "ineFrontRejection",
  ineBackValidated: "ineBackRejection",
  curpValidated: "curpRejection",
  waiverAgreementValidated: "waiverAgreementRejection",
} as const satisfies Record<
  MemberDocumentField,
  keyof MemberWithDocumentRejections
>;

/** Un miembro con al menos un documento sin validar, junto con su `clients/{uid}`. */
export interface PendingMember {
  member: MemberWithDocumentRejections;
  client: CoreClient | null;
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
