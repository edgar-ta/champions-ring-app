import type { Timestamp } from "firebase/firestore";

/**
 * `clients/{uid}` (Modelo de Datos en Firebase v20.0.0).
 * Toda persona que acude al gimnasio: prospectos, usuarios ocasionales y miembros.
 * Un miembro además tiene `members/{uid}` con el mismo uid.
 */
export interface Client {
  uid: string;
  name: string;
  lastName: string;
  email: string;

  sampleClassDate?: Timestamp | null;

  creationDate: Timestamp;
  deletionDate?: Timestamp | null;
}
