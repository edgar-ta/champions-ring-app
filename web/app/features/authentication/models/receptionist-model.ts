import type { Timestamp } from "firebase/firestore";

/** Documento de `receptionists/{uid}` (Modelo de Datos en Firebase v20.0.0). */
export interface Receptionist {
  uid: string;
  name: string;
  lastName: string;
  email: string;

  creationDate: Timestamp;
  deletionDate?: Timestamp | null;
}
