import type { Metadata } from "next";
import { ReceptionistGate } from "../features/authentication/components/receptionist-session";
import { MembershipPlansBoard } from "../features/membership-plans/components/membership-plans-board";

export const metadata: Metadata = { title: "Membresías | Champions Ring" };

export default function MembershipsPage() {
  return <ReceptionistGate><MembershipPlansBoard /></ReceptionistGate>;
}
