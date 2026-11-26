import { collection, type CollectionReference, type DocumentData, type FirestoreDataConverter } from "firebase/firestore";

import type { CoreClient } from "../models/core_client";
import type { CoreMember } from "../models/core_member";
import type { CoreMembershipPlan } from "../models/core_membership_plan";
import type { CorePayment } from "../models/core_payment";
import type { CoreRenewal } from "../models/core_renewal";
import { db } from "./firebase";

/** @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ] */
/** Nombres de las colecciones del Modelo de Datos en Firebase v22.1.0. */
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

export const clientsCollection = () => typed<CoreClient>(COLLECTIONS.clients);
export const membersCollection = () => typed<CoreMember>(COLLECTIONS.members);
export const renewalsCollection = (memberUid: string) => typed<CoreRenewal>(COLLECTIONS.members, memberUid, COLLECTIONS.renewals);
export const membershipPlansCollection = () => typed<CoreMembershipPlan>(COLLECTIONS.membershipPlans);
export const paymentsCollection = () => typed<CorePayment>(COLLECTIONS.payments);
