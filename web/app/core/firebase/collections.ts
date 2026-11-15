import { collection, type CollectionReference, type DocumentData, type FirestoreDataConverter } from "firebase/firestore";

import type { Client } from "../models/client";
import type { Member } from "../models/member";
import type { MembershipPlan } from "../models/membership-plan";
import type { Payment } from "../models/payment";
import type { Renewal } from "../models/renewal";
import { db } from "./firebase";

/** Nombres de las colecciones del Modelo de Datos en Firebase v20.0.0. */
export const COLLECTIONS = {
  clients: "clients",
  members: "members",
  renewals: "renewals",
  receptionists: "receptionists",
  administrators: "administrators",
  membershipPlans: "membership_plans",
  payments: "payments",
} as const;

function typed<T extends DocumentData>(path: string, ...segments: string[]): CollectionReference<T, DocumentData> {
  const converter: FirestoreDataConverter<T, DocumentData> = {
    toFirestore: (value) => value as DocumentData,
    fromFirestore: (snapshot) => snapshot.data() as T,
  };
  return collection(db, path, ...segments).withConverter(converter);
}

export const clientsCollection = () => typed<Client>(COLLECTIONS.clients);
export const membersCollection = () => typed<Member>(COLLECTIONS.members);
export const renewalsCollection = (memberUid: string) => typed<Renewal>(COLLECTIONS.members, memberUid, COLLECTIONS.renewals);
export const membershipPlansCollection = () => typed<MembershipPlan>(COLLECTIONS.membershipPlans);
export const paymentsCollection = () => typed<Payment>(COLLECTIONS.payments);
