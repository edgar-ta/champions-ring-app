import type { Metadata } from "next";
import { PanelShell } from "../../../src/shared/components/panel-shell";
import { ReceptionistGate } from "../../../src/features/authentication/components/receptionist-session";
import { RegistrationWizard } from "../../../src/features/signup/components/registration-wizard";

export const metadata: Metadata = { title: "Registrar alumno | Champions Ring" };

export default function RegisterPage() {
  return <ReceptionistGate><PanelShell wide title="Registrar nuevo alumno" description="Registro desde cero de alumnos (adultos y menores de edad), visitas y clases muestra."><RegistrationWizard /></PanelShell></ReceptionistGate>;
}
