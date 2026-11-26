import { doc, getDocs, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";

import { DURATION_DAYS } from "@/src/core/constants/membership";
import { membershipPlansCollection } from "@/src/core/firebase/collections";
import { DURATION_LABELS } from "@/src/core/models/core_membership_plan";
import type { MembershipPlanInput, MembershipPlanRepository } from "./membership-plan-repository";

/** @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ] */
const fields = ({ cost, benefits, duration }: MembershipPlanInput) => ({
  cost: Number(cost),
  benefits: benefits.trim(),
  duration,
  name: DURATION_LABELS[duration],
  isRenewable: duration !== "1d",
});

export const firebaseMembershipPlanRepository: MembershipPlanRepository = {
  async listPlans() {
    const snapshot = await getDocs(membershipPlansCollection());
    return snapshot.docs
      .map(document => ({ id: document.id, plan: document.data(), active: document.data().deletionDate == null }))
      .sort((a, b) => (DURATION_DAYS[a.plan.duration] ?? 99) - (DURATION_DAYS[b.plan.duration] ?? 99) || Number(b.active) - Number(a.active));
  },

  async createPlan(input) {
    const reference = doc(membershipPlansCollection());
    await setDoc(reference, { uid: reference.id, ...fields(input), creationDate: serverTimestamp() });
    return reference.id;
  },

  async updatePlan(id, input) {
    await updateDoc(doc(membershipPlansCollection(), id), fields(input));
  },

  async deactivatePlan(id) {
    await updateDoc(doc(membershipPlansCollection(), id), { deletionDate: serverTimestamp() });
  },

  async reactivatePlan(id) {
    await updateDoc(doc(membershipPlansCollection(), id), { deletionDate: null });
  },
};
