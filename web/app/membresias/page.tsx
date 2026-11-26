import type { Metadata } from "next";
import { ReceptionistGate } from "../../src/features/authentication/components/receptionist-session";
import { MembershipPlansBoard } from "../../src/features/membership-plans/components/membership-plans-board";

export const metadata: Metadata = { title: "Membresías | Champions Ring" };

export default function MembershipsPage() {
  return <ReceptionistGate><MembershipPlansBoard /></ReceptionistGate>;
}
