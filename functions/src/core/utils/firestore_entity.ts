import type {DocumentData} from "firebase-admin/firestore";

/** Contrato base de una entidad almacenada como documento de Firestore. */
export abstract class FirestoreEntity {
  /** Identificador del documento. */
  abstract readonly uid: string;

  /** Convierte la entidad a datos compatibles con Firestore. */
  abstract toFirestore(): DocumentData;
}
