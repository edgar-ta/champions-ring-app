import type { Timestamp } from "firebase/firestore";

export interface Receptionist {
  uid: string;
  name: string;
  last_name: string;
  type: "receptionist";
  birth_date: string;
  email: string;
  phone: string;
  legal_data_are_theirs: boolean;
  signature_url: string;
  ine_url: string;
  registration_payed: boolean;
  creation_date: Timestamp;
  deletion_date?: Timestamp | null;
}
