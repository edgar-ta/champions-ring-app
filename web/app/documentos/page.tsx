import type { Metadata } from "next";
import { PanelShell } from "../../src/shared/components/panel-shell";
import { ReceptionistGate } from "../../src/features/authentication/components/receptionist-session";
import { DocumentValidationList } from "../../src/features/document-validation/components/document-validation-list";

export const metadata: Metadata = { title: "Documentos | Champions Ring" };

export default function Page() {
  return <ReceptionistGate><PanelShell title="Documentos" description="Revisa y valida la INE, la CURP y la carta responsiva de los miembros nuevos."><DocumentValidationList /></PanelShell></ReceptionistGate>;
}
