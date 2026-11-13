import type { Metadata } from "next";
import { ReceptionDashboard } from "./reception-dashboard";

export const metadata: Metadata = { title: "Panel de recepción | Champions Ring" };

export default function ReceptionPage() {
  return <ReceptionDashboard />;
}
