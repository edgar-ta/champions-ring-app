import type { Metadata } from "next";
import { ReceptionistGate } from "../../src/features/authentication/components/receptionist-session";
import { SettingsScreen } from "./settings-screen";

export const metadata: Metadata = { title: "Configuración | Champions Ring" };

export default function SettingsPage() {
  return <ReceptionistGate><SettingsScreen /></ReceptionistGate>;
}
