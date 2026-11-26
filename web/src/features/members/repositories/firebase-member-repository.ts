import { doc, getDoc, getDocs, limit, orderBy, query, type DocumentReference } from "firebase/firestore";

import { clientsCollection, membersCollection, membershipPlansCollection, paymentsCollection, renewalsCollection } from "@/src/core/firebase/collections";
import { hasPendingDocuments, type CoreMember } from "@/src/core/models/core_member";
import {
  DURATION_LABELS,
  type CoreMembershipPlan,
} from "@/src/core/models/core_membership_plan";
import type { CoreRenewal } from "@/src/core/models/core_renewal";
import { ageOn, toDate } from "@/src/core/utils/format";
import { membershipStatus, type MemberSummary } from "../models/member-summary";
import type { Visit, VisitorSummary } from "../models/visitor-summary";
import type { MemberRepository } from "./member-repository";

/** Renovación vigente más reciente: la de latestRenewalRef o, si no la hay, la de mayor endDate. */
async function latestRenewal(member: CoreMember): Promise<CoreRenewal | null> {
  if (member.latestRenewalRef) {
    const snapshot = await getDoc(member.latestRenewalRef as DocumentReference<CoreRenewal>);
    const renewal = snapshot.data();
    if (renewal && renewal.deletionDate == null) return renewal;
  }
  const snapshot = await getDocs(query(renewalsCollection(member.uid), orderBy("endDate", "desc"), limit(5)));
  return snapshot.docs.map(document => document.data()).find(renewal => renewal.deletionDate == null) ?? null;
}

async function summarize(
  member: CoreMember,
  plans: Map<string, CoreMembershipPlan>,
  now: Date,
): Promise<MemberSummary> {
  const [clientSnapshot, renewal] = await Promise.all([
    getDoc(doc(clientsCollection(), member.uid)),
    latestRenewal(member),
  ]);
  const client = clientSnapshot.data();
  const birthDate = toDate(member.birthDate);
  const planRef = renewal?.membershipPlanRef ?? member.membershipPlanRef;
  const plan = planRef ? plans.get(planRef.id) : undefined;
  const membershipEnd = toDate(renewal?.endDate);

  return {
    uid: member.uid,
    fullName: client ? `${client.name} ${client.lastName}`.trim() : "Sin nombre registrado",
    email: client?.email ?? "",
    phone: member.phone ?? "",
    photoUrl: member.photoUrl ?? null,
    age: birthDate ? ageOn(birthDate, now) : null,
    guardianName: member.guardianName ?? null,
    inscriptionPaid: member.inscriptionPaid === true,
    documentsValidated: !hasPendingDocuments(member),
    planId: planRef?.id ?? null,
    planLabel: plan ? DURATION_LABELS[plan.duration] ?? plan.duration : null,
    membershipEnd,
    status: membershipStatus(membershipEnd, now),
    creationDate: toDate(member.creationDate),
    record: member,
  };
}

export const firebaseMemberRepository: MemberRepository = {
  async listMembers() {
    const [membersSnapshot, plansSnapshot] = await Promise.all([
      getDocs(membersCollection()),
      getDocs(membershipPlansCollection()),
    ]);
    const plans = new Map(plansSnapshot.docs.map(document => [document.id, document.data()]));
    const now = new Date();
    const members = membersSnapshot.docs
      .map(document => ({ ...document.data(), uid: document.data().uid ?? document.id }))
      .filter(member => member.deletionDate == null);

    const summaries = await Promise.all(members.map(member => summarize(member, plans, now)));
    return summaries.sort((a, b) => (b.creationDate?.getTime() ?? 0) - (a.creationDate?.getTime() ?? 0));
  },

  async listVisitors(memberUids) {
    // Se leen ambas colecciones una sola vez y los pagos se agrupan por cliente (payerRef).
    const [clientsSnapshot, paymentsSnapshot] = await Promise.all([
      getDocs(clientsCollection()),
      getDocs(paymentsCollection()),
    ]);

    const visitsByClient = new Map<string, Visit[]>();
    for (const document of paymentsSnapshot.docs) {
      const payment = document.data();
      const payerUid = payment.payerRef?.id;
      const date = toDate(payment.creationDate) ?? toDate(payment.approvalDate);
      if (!payerUid || !date || payment.deletionDate != null || memberUids.has(payerUid)) continue;
      const visits = visitsByClient.get(payerUid) ?? [];
      visits.push({
        paymentUid: payment.uid ?? document.id,
        date,
        amount: Number(payment.amount) || 0,
        type: payment.type,
        pending: payment.approvalDate == null,
      });
      visitsByClient.set(payerUid, visits);
    }

    return clientsSnapshot.docs
      .map(document => ({ ...document.data(), uid: document.data().uid ?? document.id }))
      .filter(client => client.deletionDate == null && !memberUids.has(client.uid))
      .map((client): VisitorSummary => {
        const visits = (visitsByClient.get(client.uid) ?? []).sort((a, b) => b.date.getTime() - a.date.getTime());
        const sampleClassDate = toDate(client.sampleClassDate);
        return {
          uid: client.uid,
          fullName: `${client.name ?? ""} ${client.lastName ?? ""}`.trim() || "Sin nombre registrado",
          email: client.email ?? "",
          // @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
          // En v22.1.0 los pagos no dicen a qué plan corresponden; para quien no es alumno, cada pago es una visita.
          kind: visits.length > 0 || !sampleClassDate ? "visit" : "sample",
          sampleClassDate,
          visits,
          lastDate: visits[0]?.date ?? sampleClassDate,
          creationDate: toDate(client.creationDate),
        };
      });
  },
};
