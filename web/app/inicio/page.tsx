import type { Metadata } from "next";
import { ReceptionistGate } from "../../src/features/authentication/components/receptionist-session";
import { ReceptionDashboard } from "./reception-dashboard";

export const metadata: Metadata = { title: "Panel de recepción | Champions Ring" };

export default function ReceptionPage() {
  return <ReceptionistGate><ReceptionDashboard /></ReceptionistGate>;
}
